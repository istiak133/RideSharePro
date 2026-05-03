import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late Future<List<dynamic>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _fetchTrips();
  }

  Future<List<dynamic>> _fetchTrips() async {
    try {
      final res = await ApiService.get('/rides/history/me');
      return res['data']['rides'] as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        title: const Text('My Trips', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load trips', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _tripsFuture = _fetchTrips()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.bgSurface, shape: BoxShape.circle),
                    child: const Icon(Icons.history, size: 64, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 24),
                  const Text('No trips yet', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Your past rides and parcels will appear here', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }

          final trips = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _buildTripCard(trip);
            },
          );
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final bool isCompleted = trip['status'] == 'completed';
    final bool isCancelled = trip['status'] == 'cancelled';
    
    Color statusColor = AppTheme.primary;
    if (isCompleted) statusColor = AppTheme.success;
    if (isCancelled) statusColor = AppTheme.error;

    // Parse date
    final createdAt = DateTime.parse(trip['created_at']).toLocal();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgSurface),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header: Date & Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    trip['status'].toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppTheme.bgSurface, height: 1),
          
          // Body: Locations & Fare
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vehicle Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
                  child: Icon(
                    trip['vehicle_type'] == 'bike' ? Icons.two_wheeler : Icons.local_taxi,
                    color: AppTheme.textSecondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Addresses
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationRow(Icons.circle, AppTheme.secondary, trip['pickup_address'] ?? 'Unknown Pickup'),
                      Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Container(width: 2, height: 12, color: AppTheme.bgSurface),
                      ),
                      _buildLocationRow(Icons.location_on, AppTheme.accent, trip['drop_address'] ?? 'Unknown Drop'),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Fare
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Fare', style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    Text(
                      '৳${trip['estimated_fare']}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
