import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/screens/chat_screen.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:rideshare_app/services/location_service.dart';

enum DriverRideState { goingToPickup, arrivedAtPickup, onTrip }

class DriverActiveRideScreen extends StatefulWidget {
  final Map<String, dynamic> rideRequest;

  const DriverActiveRideScreen({super.key, required this.rideRequest});

  @override
  State<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  DriverRideState _currentState = DriverRideState.goingToPickup;
  final TextEditingController _otpController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _driverLoc = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  late LatLng _pickupLoc;
  late LatLng _dropLoc;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _pickupLoc = LatLng(widget.rideRequest['pickup_lat'] ?? AppConfig.defaultLat, widget.rideRequest['pickup_lng'] ?? AppConfig.defaultLng);
    _dropLoc = LatLng(widget.rideRequest['drop_lat'] ?? AppConfig.defaultLat, widget.rideRequest['drop_lng'] ?? AppConfig.defaultLng);
    
    // Start tracking driver location
    LocationService.startTracking((loc) {
      if (mounted) setState(() => _driverLoc = loc);
    });

    _fetchRoute();
  }

  @override
  void dispose() {
    LocationService.stopTracking();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoadingRoute = true);
    final start = _currentState == DriverRideState.goingToPickup ? _driverLoc : _pickupLoc;
    final end = _currentState == DriverRideState.goingToPickup ? _pickupLoc : _dropLoc;
    
    final routeData = await LocationService.getRoute(start, end);
    if (mounted && routeData != null) {
      setState(() {
        _routePoints = routeData['points'];
        _isLoadingRoute = false;
      });
      _fitMapToRoute();
    } else if (mounted) {
      setState(() => _isLoadingRoute = false);
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude, maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude, maxLng = _routePoints.first.longitude;
    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
      padding: const EdgeInsets.only(top: 50, left: 50, right: 50, bottom: 350),
    ));
  }

  void _onSwipeAction() async {
    if (_currentState == DriverRideState.goingToPickup) {
      setState(() => _currentState = DriverRideState.arrivedAtPickup);
      _fetchRoute(); // re-fetch route for pickup -> dropoff (it will be drawn once trip starts, but good to load)
    } else if (_currentState == DriverRideState.onTrip) {
      _showRideCompleteDialog();
    }
  }

  void _verifyOTP() async {
    if (_otpController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 4-digit OTP'), backgroundColor: AppTheme.error));
      return;
    }

    try {
      await ApiService.post('/rides/${widget.rideRequest['id']}/verify-otp', body: {'otp': _otpController.text});
      await ApiService.put('/rides/${widget.rideRequest['id']}/start');
      
      setState(() {
        _currentState = DriverRideState.onTrip;
        _otpController.clear();
      });
      _fetchRoute(); // draw route to dropoff
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Verified! Trip Started.'), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.error));
    }
  }

  void _showRideCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Ride Completed! 🎉', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Collect Cash or Wait for Online Payment.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            Text('Fare: ৳${widget.rideRequest['estimated_fare']}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.success)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.put('/rides/${widget.rideRequest['id']}/complete');
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to Home
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete: $e'), backgroundColor: AppTheme.error));
              }
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentState == DriverRideState.onTrip ? _dropLoc : _pickupLoc,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 5, color: Colors.blueAccent),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(point: _driverLoc, child: const Icon(Icons.drive_eta, color: AppTheme.primary, size: 30)),
                  if (_currentState != DriverRideState.onTrip)
                    Marker(point: _pickupLoc, child: const Icon(Icons.person_pin_circle, color: AppTheme.warning, size: 30)),
                  if (_currentState == DriverRideState.onTrip)
                    Marker(point: _dropLoc, child: const Icon(Icons.location_on, color: AppTheme.error, size: 30)),
                ],
              ),
            ],
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppTheme.bgCard,
              child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
          ),

          // Top Info Banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 70, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.bgCard.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(16)),
              child: Text(
                _currentState == DriverRideState.goingToPickup 
                    ? 'Heading to Pickup: ${widget.rideRequest['pickup_address']}'
                    : _currentState == DriverRideState.arrivedAtPickup 
                        ? 'Wait for Rider to arrive'
                        : 'Heading to Drop-off: ${widget.rideRequest['drop_address']}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildBottomContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent() {
    if (_currentState == DriverRideState.arrivedAtPickup) {
      return _buildOTPState();
    }

    final isTrip = _currentState == DriverRideState.onTrip;
    
    return Column(
      key: ValueKey(_currentState),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=60')),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rider Name', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Cash Payment • ৳120', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: AppTheme.primary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble, color: AppTheme.primary),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ChatScreen(
                    rideId: 'dummy_ride_id',
                    receiverName: 'Rider Name',
                  ),
                ));
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        SwipeableButton(
          text: isTrip ? 'Swipe to Complete Ride' : 'Swipe to Arrive',
          color: isTrip ? AppTheme.error : AppTheme.primary,
          onSwipe: _onSwipeAction,
        ),
      ],
    );
  }

  Widget _buildOTPState() {
    return Column(
      key: const ValueKey('otp'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, color: AppTheme.warning, size: 40),
        const SizedBox(height: 12),
        const Text('Enter OTP to Start Trip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Ask the rider for the 4-digit PIN', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.white),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: AppTheme.bgSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyOTP,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Verify & Start', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

// Custom Swipe Button
class SwipeableButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onSwipe;

  const SwipeableButton({super.key, required this.text, required this.color, required this.onSwipe});

  @override
  State<SwipeableButton> createState() => _SwipeableButtonState();
}

class _SwipeableButtonState extends State<SwipeableButton> {
  double _dragPosition = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxDrag = constraints.maxWidth - 60;
      
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          children: [
            Center(child: Text(widget.text, style: TextStyle(color: widget.color.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.bold))),
            Positioned(
              left: _dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (_isFinished) return;
                  setState(() {
                    _dragPosition += details.delta.dx;
                    if (_dragPosition < 0) _dragPosition = 0;
                    if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_dragPosition > maxDrag * 0.8) {
                    setState(() {
                      _dragPosition = maxDrag;
                      _isFinished = true;
                    });
                    widget.onSwipe();
                  } else {
                    setState(() => _dragPosition = 0);
                  }
                },
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 10)]),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
