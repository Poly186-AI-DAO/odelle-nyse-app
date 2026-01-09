import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
      ),
    );
  }
}
