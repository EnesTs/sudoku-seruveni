import 'package:flutter/material.dart';
import '../models/theme_model.dart';

class ThemedBackground extends StatelessWidget {
  final AppTheme theme;
  final Widget child;

  const ThemedBackground({
    Key? key,
    required this.theme,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Temanın rengine uygun yumuşak bir gradyan arka plan
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.backgroundColor,
                  theme.primaryColor.withOpacity(0.2),
                ],
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.spaceAround,
              children: List.generate(
                35,
                (index) => Opacity(
                  opacity: 0.15, // Şekilleri ve sembolleri daha belirgin yapar
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      theme.backgroundIcons[index % theme.backgroundIcons.length],
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sayfa İçeriği
        child,
      ],
    );
  }
}