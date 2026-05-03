import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/screens/chat_screen.dart';

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

  final LatLng _driverLoc = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  late LatLng _pickupLoc;
  late LatLng _dropLoc;

  @override
  void initState() {
    super.initState();
    // In real app, these come from widget.rideRequest lat/lng
    _pickupLoc = LatLng(_driverLoc.latitude + 0.01, _driverLoc.longitude + 0.01);
    _dropLoc = LatLng(_driverLoc.latitude - 0.02, _driverLoc.longitude - 0.02);
  }

  void _onSwipeAction() {
    if (_currentState == DriverRideState.goingToPickup) {
      setState(() => _currentState = DriverRideState.arrivedAtPickup);
    } else if (_currentState == DriverRideState.onTrip) {
      _showRideCompleteDialog();
    }
  }

  void _verifyOTP() {
    if (_otpController.text.length == 4) {
      setState(() => _currentState = DriverRideState.onTrip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified! Trip Started.'), backgroundColor: AppTheme.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 4-digit OTP'), backgroundColor: AppTheme.error),
      );
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to Home
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
            options: MapOptions(
              initialCenter: _currentState == DriverRideState.onTrip ? _dropLoc : _pickupLoc,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
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
