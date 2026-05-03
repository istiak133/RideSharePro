import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rideshare_app/config/theme.dart';
import 'package:rideshare_app/providers/auth_provider.dart';
import 'package:rideshare_app/screens/auth/phone_login_screen.dart';
import 'package:rideshare_app/services/api_service.dart';
import 'package:rideshare_app/screens/driver/driver_document_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  String _status = 'unverified';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await ApiService.get('/users/driver/verification-status');
      if (mounted) {
        setState(() {
          _status = res['data']['status'] ?? 'unverified';
          _rejectionReason = res['data']['rejection_reason'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));

    Color statusColor = AppTheme.warning;
    if (_status == 'approved') statusColor = AppTheme.success;
    if (_status == 'rejected') statusColor = AppTheme.error;

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
            const SizedBox(height: 8),
            
            // Verification Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _status == 'approved' ? Icons.check_circle : (_status == 'rejected' ? Icons.cancel : Icons.pending),
                    color: statusColor, size: 20
                  ),
                  const SizedBox(width: 8),
                  Text(_status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (_status == 'rejected' && _rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Reason: $_rejectionReason', style: const TextStyle(color: AppTheme.error)),
              ),
            const SizedBox(height: 32),

            // Vehicle Details
            _buildSectionHeader('Verification Documents'),
            if (_status == 'unverified' || _status == 'rejected')
              _buildProfileOption(Icons.upload_file, 'Upload Documents', 'Action Required', valueColor: AppTheme.error, onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDocumentScreen()));
                if (result == true) _fetchStatus(); // refresh
              })
            else
              _buildProfileOption(Icons.description, 'Registration Papers', 'Verified', onTap: () {}, valueColor: AppTheme.success),

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
