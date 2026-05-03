import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/screens/chat_screen.dart';

enum RideState { searching, driverAssigned, rideStarted }

class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  final LatLng pickupLocation;
  final LatLng dropLocation;
  final List<LatLng> routePoints;
  final String otp;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    required this.pickupLocation,
    required this.dropLocation,
    required this.routePoints,
    required this.otp,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  RideState _rideState = RideState.searching;
  
  // Animation for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup Pulse Animation for 'Searching'
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Simulate driver finding after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted && _rideState == RideState.searching) {
        setState(() => _rideState = RideState.driverAssigned);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _fitMapToRoute() {
    if (widget.routePoints.isEmpty) return;
    
    double minLat = widget.routePoints.first.latitude;
    double maxLat = widget.routePoints.first.latitude;
    double minLng = widget.routePoints.first.longitude;
    double maxLng = widget.routePoints.first.longitude;

    for (var p in widget.routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    // Add bottom padding so the card doesn't cover the route
    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.only(top: 50, left: 50, right: 50, bottom: 300),
    ));
  }

  void _verifyOtp() {
    setState(() => _rideState = RideState.rideStarted);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ OTP Verified! Ride Started.'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.pickupLocation,
              initialZoom: AppConfig.defaultZoom,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: widget.routePoints, strokeWidth: 5, color: Colors.blueAccent),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(point: widget.pickupLocation, child: const Icon(Icons.circle, color: Colors.blue, size: 16)),
                  Marker(point: widget.dropLocation, child: const Icon(Icons.location_on, color: Colors.red, size: 30)),
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Status Card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildStatusContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_rideState) {
      case RideState.searching:
        return _buildSearchingState();
      case RideState.driverAssigned:
        return _buildDriverAssignedState();
      case RideState.rideStarted:
        return _buildRideStartedState();
    }
  }

  Widget _buildSearchingState() {
    return Column(
      key: const ValueKey('searching'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.2),
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: const Icon(Icons.search, color: AppTheme.primary, size: 40),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Searching for nearby drivers...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(color: AppTheme.primary, backgroundColor: AppTheme.bgSurface),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel Request', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }

  Widget _buildDriverAssignedState() {
    return Column(
      key: const ValueKey('assigned'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Driver is arriving in 3 min', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('OTP: ${widget.otp}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const CircleAvatar(radius: 26, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rahim Uddin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('Honda CBR • DHAKA-H-12-3456', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                const Text('4.9', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _verifyOtp,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Verify OTP (Demo)'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.bgSurface,
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.primary),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(rideId: widget.rideId, receiverName: 'Rahim Uddin'),
                  ));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideStartedState() {
    return Column(
      key: const ValueKey('started'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.two_wheeler, color: AppTheme.primary, size: 60),
        const SizedBox(height: 16),
        const Text('On route to destination', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Enjoy your ride safely!', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // End Ride Demo
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('End Ride (Demo)'),
          ),
        )
      ],
    );
  }
}
