import 'package:flutter/material.dart';

class GrowthViewWidget extends StatelessWidget {
  const GrowthViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'График роста',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Скоро появится',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}