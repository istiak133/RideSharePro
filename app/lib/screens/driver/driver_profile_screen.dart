import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/phone_login_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rahim Uddin', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('+880 1711-223344', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            
            // Rating Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: AppTheme.warning, size: 20),
                  SizedBox(width: 8),
                  Text('4.8 Rating', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Vehicle Details
            _buildSectionHeader('Vehicle Details'),
            _buildProfileOption(Icons.directions_car, 'Toyota Corolla 2018', 'Dhaka Metro Ga-12-3456', onTap: () {}),
            _buildProfileOption(Icons.description, 'Registration Papers', 'Verified', onTap: () {}, valueColor: AppTheme.success),
            _buildProfileOption(Icons.badge, 'Driving License', 'Valid till 2028', onTap: () {}),

            const SizedBox(height: 24),
            _buildSectionHeader('Account Settings'),
            _buildProfileOption(Icons.language, 'Language', 'English', onTap: () {}),
            _buildProfileOption(Icons.help_outline, 'Help & Support', '', onTap: () {}),
            
            const SizedBox(height: 24),
            
            // Logout
            GestureDetector(
              onTap: () async {
                final auth = context.read<AuthProvider>();
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()), (r) => false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, String value, {required VoidCallback onTap, Color? valueColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            if (value.isNotEmpty)
              Text(value, style: TextStyle(color: valueColor ?? AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}
