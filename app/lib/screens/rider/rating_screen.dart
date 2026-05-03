import 'package:flutter/material.dart';
import 'package:rideshare_app/config/theme.dart';

class RatingScreen extends StatefulWidget {
  final String rideId;

  const RatingScreen({super.key, required this.rideId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitRating() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    // In a real app, send to /api/ratings
    // ApiService.post('/ratings', body: { 'ride_id': widget.rideId, 'rating': _rating, 'comment': _feedbackController.text });
    
    // For demo, just show success and return to home
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Thank You!', style: TextStyle(color: Colors.white)),
        content: const Text('Your feedback has been submitted successfully.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst); // Return to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
        automaticallyImplyLeading: false, // Force them to rate or skip
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Skip', style: TextStyle(color: AppTheme.textHint)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
            const SizedBox(height: 16),
            const Text('How was your trip with', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Rahim Uddin?', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? Colors.amber : AppTheme.textHint,
                    size: 48,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            
            const SizedBox(height: 40),
            
            // Feedback input
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Leave a comment (optional)',
                alignLabelWithHint: true,
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
