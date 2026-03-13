// lib/ui/home/widgets/language_chip_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanimitra/ui/home/home_controller.dart';

class LanguageChipRow extends StatelessWidget {
  const LanguageChipRow({super.key});

  static const _chips = [
    ('en', 'EN'),
    ('hi', 'हिं'),
    ('ta', 'த'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _chips.map((chip) {
            final isSelected = controller.language == chip.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.setLanguage(chip.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? Colors.greenAccent.withOpacity(0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.24),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    chip.$2,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.54),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
