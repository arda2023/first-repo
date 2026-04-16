import "package:flutter/material.dart";

class WeatherInfoCard extends StatelessWidget {
  final String title;
  final String value;
  const WeatherInfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [Text(title), SizedBox(height: 8), Text(value)]),
    );
  }
}
