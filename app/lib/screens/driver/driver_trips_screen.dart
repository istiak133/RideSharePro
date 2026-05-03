import 'package:flutter/material.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/services/api_service.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _earnings = {};
  List<dynamic> _recentTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final earnRes = await ApiService.get('/payments/earnings');
      final histRes = await ApiService.get('/rides/history/me');
      
      if (mounted) {
        setState(() {
          _earnings = earnRes['data'] ?? {};
          _recentTrips = histRes['data']['rides'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final todayEarnings = _earnings['today_earnings']?.toString() ?? '0';
    final todayTrips = _earnings['today_trips']?.toString() ?? '0';
    final totalEarnings = _earnings['total_earnings']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Earnings & Trips'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Text('Today\'s Earnings', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('৳ $todayEarnings', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Trips', todayTrips),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStat('Total', '৳$totalEarnings'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Trips List
            const Text('Recent Trips', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (_recentTrips.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No completed trips yet', style: TextStyle(color: AppTheme.textHint))))
            else
              ..._recentTrips.map((trip) {
                final dateStr = trip['completed_at'] ?? trip['created_at'];
                final date = DateTime.parse(dateStr).toLocal();
                final formattedDate = '${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                
                return _buildTripTile(
                  date: formattedDate,
                  pickup: trip['pickup_address'] ?? 'Unknown',
                  drop: trip['drop_address'] ?? 'Unknown',
                  fare: '৳ ${trip['final_fare'] ?? trip['estimated_fare']}',
                  status: trip['status'],
                );
              }),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildTripTile({required String date, required String pickup, required String drop, required String fare, required String status}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(fare, style: const TextStyle(color: AppTheme.primary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.my_location, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(pickup, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            child: Icon(Icons.more_vert, color: AppTheme.textHint, size: 16),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(drop, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }
}
