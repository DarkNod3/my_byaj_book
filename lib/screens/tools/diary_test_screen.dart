import 'package:flutter/material.dart';

class DiaryTestScreen extends StatelessWidget {
  final String diaryType;

  const DiaryTestScreen({
    Key? key,
    required this.diaryType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(diaryType),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForDiary(),
              size: 80,
              color: _getColorForDiary(),
            ),
            const SizedBox(height: 24),
            Text(
              diaryType,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is the $diaryType screen',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDiary() {
    switch (diaryType) {
      case 'Milk Diary':
        return Icons.local_drink_rounded;
      case 'Daily Work Diary':
        return Icons.work_rounded;
      case 'Tea Stall Diary':
        return Icons.emoji_food_beverage_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  Color _getColorForDiary() {
    switch (diaryType) {
      case 'Milk Diary':
        return Colors.amber.shade700;
      case 'Daily Work Diary':
        return Colors.blue;
      case 'Tea Stall Diary':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
} 