import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, 'Akun', isActive: currentStep >= 1, isCompleted: currentStep > 1),
        _buildLine(isActive: currentStep > 1),
        _buildStep(2, 'Profil Ibu', isActive: currentStep >= 2, isCompleted: currentStep > 2),
        _buildLine(isActive: currentStep > 2),
        _buildStep(3, 'Profil Anak', isActive: currentStep >= 3, isCompleted: currentStep > 3),
      ],
    );
  }

  Widget _buildStep(int step, String title, {required bool isActive, required bool isCompleted}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.transparent),
            border: Border.all(
              color: isActive || isCompleted ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.white, size: 18)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? AppColors.white : AppColors.textSecondary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
            color: isActive || isCompleted ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
        height: 2,
        color: isActive ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
      ),
    );
  }
}
