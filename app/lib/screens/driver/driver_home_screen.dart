// ============================================
// Driver Home Screen — Go Online + Accept Rides
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/app_config.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/phone_login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  int _currentIndex = 0;
  final LatLng _currentLocation = LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: AppConfig.defaultZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rideshareai.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _currentLocation,
                  width: 60, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (_isOnline ? AppTheme.online : AppTheme.textHint).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.drive_eta, color: _isOnline ? AppTheme.online : AppTheme.textHint, size: 30),
                  ),
                ),
              ]),
            ],
          ),

          // Status bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: _isOnline ? AppTheme.online : AppTheme.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isOnline ? 'অনলাইন' : 'অফলাইন',
                      style: TextStyle(
                        color: _isOnline ? AppTheme.online : AppTheme.textHint,
                        fontWeight: FontWeight.w600, fontSize: 16,
                      ),
                    ),
                  ]),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(children: [
                        Icon(Icons.star, color: AppTheme.warning, size: 18),
                        SizedBox(width: 4),
                        Text('4.8', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()), (r) => false);
                        }
                      },
                      child: const Icon(Icons.logout_rounded, color: AppTheme.textHint),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // Go online/offline button
          Positioned(
            bottom: 100, left: 16, right: 16,
            child: Column(
              children: [
                // Stats row
                if (_isOnline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('আজকের আয়', '৳ 0'),
                        Container(width: 1, height: 30, color: AppTheme.textHint),
                        _statItem('ট্রিপ', '0'),
                        Container(width: 1, height: 30, color: AppTheme.textHint),
                        _statItem('ঘণ্টা', '0.0'),
                      ],
                    ),
                  ),

                // Toggle button
                GestureDetector(
                  onTap: () => setState(() => _isOnline = !_isOnline),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: _isOnline
                          ? const LinearGradient(colors: [AppTheme.accent, Color(0xFFFF8787)])
                          : const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: (_isOnline ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.4),
                        blurRadius: 20, offset: const Offset(0, 8),
                      )],
                    ),
                    child: Center(
                      child: Text(
                        _isOnline ? '🔴  অফলাইন হোন' : '🟢  অনলাইন হোন',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppTheme.bgCard,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'হোম'),
          NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'ট্রিপ'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_rounded), label: 'আয়'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'প্রোফাইল'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}
