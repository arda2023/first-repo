import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/forecast_item.dart';
import '../widgets/svg_adaptive_backdrop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget buildWeatherStat(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.white),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: const Color.fromARGB(255, 70, 70, 70),
    );
  }

  Widget city(IconData icon, String cityName) {
    return Row(
      children: [
        Icon(icon, size: 28, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          cityName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const String mainIconAsset = 'assets/regen.svg';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: SvgAdaptiveBackdrop(assetName: mainIconAsset),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double glowSize = math
                      .min(520.0, constraints.maxWidth)
                      .clamp(240.0, 520.0)
                      .toDouble();
                  final double iconSize = glowSize * 0.48;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                city(Icons.location_on_rounded, 'Berlin'),
                                const SizedBox(height: 4),
                                Text(
                                  'Wednesday, 15. Apr',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SvgAdaptiveGlow(
                          assetName: mainIconAsset,
                          size: glowSize,
                          strength: 0.95,
                          child: SvgPicture.asset(
                            mainIconAsset,
                            width: iconSize,
                            height: iconSize,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cloudy',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 20, 20, 20),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: buildWeatherStat(
                                  Icons.air,
                                  'Wind',
                                  '12 km/h',
                                ),
                              ),
                              buildDivider(),
                              Expanded(
                                child: buildWeatherStat(
                                  Icons.water_drop,
                                  'Humidity',
                                  '78%',
                                ),
                              ),
                              buildDivider(),
                              Expanded(
                                child: buildWeatherStat(
                                  Icons.umbrella,
                                  'Rain',
                                  '20%',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ForecastItem(
                                day: 'Mon',
                                icon: Icons.cloud,
                                iconColor: Colors.white,
                                temperature: '21Â°',
                              ),
                            ),
                            Expanded(
                              child: ForecastItem(
                                day: 'Tue',
                                icon: Icons.wb_sunny,
                                iconColor: Colors.white,
                                temperature: '24Â°',
                              ),
                            ),
                            Expanded(
                              child: ForecastItem(
                                day: 'Wed',
                                icon: Icons.cloud,
                                iconColor: Colors.white,
                                temperature: '18Â°',
                              ),
                            ),
                            Expanded(
                              child: ForecastItem(
                                day: 'Thu',
                                icon: Icons.cloud,
                                iconColor: Colors.white,
                                temperature: '18Â°',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
