import 'package:flutter/material.dart';
import 'package:rideshare_app/config/theme.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBackground,
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
                  const Text('৳ 1,450', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Trips', '6'),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStat('Hours', '4.5'),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStat('Cash', '৳850'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Weekly Summary
            const Text('Weekly Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('May 01 - May 07', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const Text('৳ 6,230', style: TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recent Trips List
            const Text('Recent Trips', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildTripTile(date: 'Today, 10:30 AM', pickup: 'Gulshan 1', drop: 'Banani', fare: '৳ 250', status: 'Completed'),
            _buildTripTile(date: 'Today, 09:15 AM', pickup: 'Badda', drop: 'Gulshan 1', fare: '৳ 150', status: 'Completed'),
            _buildTripTile(date: 'Yesterday, 04:00 PM', pickup: 'Dhanmondi 27', drop: 'Mohakhali', fare: '৳ 420', status: 'Completed'),
            _buildTripTile(date: 'Yesterday, 01:20 PM', pickup: 'Farmgate', drop: 'Dhanmondi 27', fare: '৳ 180', status: 'Completed'),
            
            const SizedBox(height: 80), // Padding for bottom nav
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
              Text(pickup, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 7, vertical: 2),
            child: Icon(Icons.more_vert, color: AppTheme.textHint, size: 16),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.error, size: 16),
              const SizedBox(width: 8),
              Text(drop, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
