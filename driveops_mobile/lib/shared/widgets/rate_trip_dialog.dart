import 'package:flutter/material.dart';
import 'package:driveops_mobile/shared/dtos/requests/trip_requests.dart';

/// Post-trip rating dialog: 1–5 stars + optional feedback.
///
/// Pops with a [RateTripRequest] on submit (`isCustomerRating` is fixed by
/// the caller — customer rates driver / driver rates customer use the same
/// dialog with the flag flipped), or null when dismissed.
class RateTripDialog extends StatefulWidget {
  final String title;
  final bool isCustomerRating;

  const RateTripDialog({
    super.key,
    required this.title,
    required this.isCustomerRating,
  });

  static Future<RateTripRequest?> show(
    BuildContext context, {
    required String title,
    required bool isCustomerRating,
  }) {
    return showDialog<RateTripRequest>(
      context: context,
      builder: (_) => RateTripDialog(
        title: title,
        isCustomerRating: isCustomerRating,
      ),
    );
  }

  @override
  State<RateTripDialog> createState() => _RateTripDialogState();
}

class _RateTripDialogState extends State<RateTripDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    final feedback = _feedbackController.text.trim();
    Navigator.of(context).pop(RateTripRequest(
      rating: _rating,
      feedback: feedback.isEmpty ? null : feedback,
      isCustomerRating: widget.isCustomerRating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Feedback (optional)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              counterStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF252538),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rating == 0 ? null : _submit,
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

/// Read-only star row for an already-submitted rating.
class RatingStars extends StatelessWidget {
  final int rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFF59E0B),
            size: size,
          ),
      ],
    );
  }
}
