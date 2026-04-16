import 'package:flutter/material.dart';

class ForecastItem extends StatelessWidget {
  final String day;
  final IconData icon;
  final Color iconColor;
  final String temperature;

  const ForecastItem({
    super.key,
    required this.day,
    required this.icon,
    required this.temperature,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 31, 31, 31),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: const TextStyle(color: Colors.white70), // Text hellgrau/weiß
          ),
          const SizedBox(height: 10),
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            temperature,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
