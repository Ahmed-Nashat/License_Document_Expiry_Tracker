import 'package:flutter/material.dart';
import '../../shared/design_tokens.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.inkDark : AppColors.ink;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.fog;
    final cardColor = isDark ? AppColors.selectedDark : AppColors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy & Terms',
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DueNest Privacy Policy', style: _headingStyle(isDark).copyWith(fontSize: 24)),
                  const SizedBox(height: 24),
                  
                  Text('Privacy Policy', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'DueNest is a privacy-first application. Your personal data, document names, '
                    'and expiry dates are stored securely and are never sold or shared with third parties. '
                    'We only process your data to provide the tracking and reminder services you requested.',
                    style: _bodyStyle(isDark),
                  ),
                  
                  const SizedBox(height: 36),
                  
                  Text('Data Deletion', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'You retain full ownership of your data. Deleting a document or your account '
                    'permanently removes the associated data from our active databases.',
                    style: _bodyStyle(isDark),
                  ),
                  
                  const SizedBox(height: 36),
                  
                  Text('Disclaimer', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'DueNest is provided "as is" without any warranties. While we strive for 100% '
                    'reliability with our email reminders, you should not rely solely on this '
                    'service for legally binding or financially critical renewals. We are not liable '
                    'for any penalties incurred due to missed expirations.',
                    style: _bodyStyle(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _headingStyle(bool isDark) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: isDark ? AppColors.inkDark : AppColors.ink,
      letterSpacing: -0.3,
    );
  }

  TextStyle _bodyStyle(bool isDark) {
    return TextStyle(
      fontSize: 15,
      height: 1.65,
      color: isDark ? AppColors.charcoalDark : AppColors.charcoal,
    );
  }
}
