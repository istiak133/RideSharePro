import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/screens/chat_screen.dart';
import 'package:rideshare_app/screens/rider/payment_screen.dart';

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
  
  RealtimeChannel? _rideChannel;
  RealtimeChannel? _driverChannel;
  LatLng? _driverLocation;
  Map<String, dynamic>? _driverInfo;

  @override
  void initState() {
    super.initState();
    
    // Setup Pulse Animation for 'Searching'
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _listenToRideStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRoute());
  }

  void _listenToRideStatus() {
    _rideChannel = Supabase.instance.client
      .channel('public:rides:id=${widget.rideId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'rides',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: widget.rideId),
        callback: (payload) {
          final newStatus = payload.newRecord['status'];
          final driverId = payload.newRecord['driver_id'];
          
          if (newStatus == 'driver_assigned' && _rideState == RideState.searching) {
            _fetchDriverInfo(driverId);
            _listenToDriverLocation(driverId);
            if (mounted) setState(() => _rideState = RideState.driverAssigned);
          } else if (newStatus == 'started') {
            if (mounted) setState(() => _rideState = RideState.rideStarted);
          } else if (newStatus == 'completed') {
            final double fareAmount = double.tryParse(payload.newRecord['final_fare']?.toString() ?? payload.newRecord['estimated_fare']?.toString() ?? '0') ?? 0.0;
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PaymentScreen(rideId: widget.rideId, fareAmount: fareAmount),
              ));
            }
          }
        },
      )
      .subscribe();
  }

  void _fetchDriverInfo(String driverId) async {
    final res = await Supabase.instance.client.from('users').select('full_name, phone, photo_url, average_rating').eq('id', driverId).single();
    if (mounted) setState(() => _driverInfo = res);
  }

  void _listenToDriverLocation(String driverId) {
    _driverChannel = Supabase.instance.client
      .channel('public:drivers:user_id=$driverId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'drivers',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: driverId),
        callback: (payload) {
          final lat = payload.newRecord['current_lat'];
          final lng = payload.newRecord['current_lng'];
          if (lat != null && lng != null && mounted) {
            setState(() => _driverLocation = LatLng(lat, lng));
            // Optional: animate map to include driver location
          }
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rideChannel?.unsubscribe();
    _driverChannel?.unsubscribe();
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
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 50, height: 50,
                      child: Container(
                        decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.drive_eta, color: AppTheme.accent, size: 28),
                      ),
                    ),
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
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.25),
                border: Border.all(color: AppTheme.primary, width: 2),
              ),
              child: const Icon(Icons.search, color: AppTheme.primary, size: 36),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Finding your ride...', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Contacting nearby drivers', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        LinearProgressIndicator(color: AppTheme.primary, backgroundColor: AppTheme.bgSurface, minHeight: 3),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.bgSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cancel Request', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
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
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        
        // Driver Arrival Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arriving in', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                Text('5 mins', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('PIN CODE', style: TextStyle(color: AppTheme.textHint, fontSize: 10, letterSpacing: 1)),
                  Text(widget.otp, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
        
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppTheme.bgSurface)),
        
        // Driver Details
        Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.bgCard, shape: BoxShape.circle),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const Text('4.9', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rahim Uddin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Honda CBR • DHAKA-H-12-3456', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Verify OTP (Demo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            _buildActionButton(Icons.chat_bubble_rounded, () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(rideId: widget.rideId, receiverName: 'Rahim Uddin'),
              ));
            }),
            const SizedBox(width: 12),
            _buildActionButton(Icons.call_rounded, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Driver...')));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 24),
      ),
    );
  }

  Widget _buildRideStartedState() {
    return Column(
      key: const ValueKey('started'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.two_wheeler, color: AppTheme.primary, size: 48),
        ),
        const SizedBox(height: 20),
        const Text('On route to destination', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Enjoy your ride safely!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              // End Ride Demo -> Go to Payment Screen
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  rideId: widget.rideId,
                  fareAmount: 120.0, // Demo fare amount
                ),
              ));
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('End Ride (Demo)', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        )
      ],
    );
  }
}
