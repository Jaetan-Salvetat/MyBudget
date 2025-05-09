import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final Color textColor;
  final Widget? extraContent;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.textColor,
    this.extraContent,
  });
}
