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
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: double.infinity,
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
                  const SizedBox(height: 8),
                  const Text('Last updated: September 2026', style: TextStyle(color: AppColors.gray, fontSize: 13)),
                  const SizedBox(height: 32),
                  
                  Text('1. Data Collection', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'DueNest is a privacy-first application. Your personal data, document names, '
                    'and expiry dates are stored securely and are never sold or shared with third parties. '
                    'We only process your data to provide the tracking and reminder services you requested.',
                    style: _bodyStyle(isDark),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text('2. Cookies & Sessions', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'DueNest uses secure, strictly-necessary cookies exclusively to keep you logged into your session. '
                    'We do not use tracking, advertising, or third-party analytics cookies.',
                    style: _bodyStyle(isDark),
                  ),

                  const SizedBox(height: 32),
                  
                  Text('3. Third-Party Services', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'To provide our service, your data is processed by trusted third-party infrastructure providers '
                    '(such as our database hosts and email delivery services). These providers are contractually '
                    'obligated to protect your data and may not use it for their own purposes.',
                    style: _bodyStyle(isDark),
                  ),

                  const SizedBox(height: 32),

                  Text('4. Security Measures', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'We take security seriously. All data transmitted between your device and our servers is encrypted using standard HTTPS. '
                    'Your passwords are never stored in plain text; they are mathematically hashed before saving.',
                    style: _bodyStyle(isDark),
                  ),

                  const SizedBox(height: 32),
                  
                  Text('5. Age Restrictions', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'DueNest is not intended for children under the age of 13 (or 16 in certain jurisdictions). '
                    'We do not knowingly collect personal information from individuals under this age.',
                    style: _bodyStyle(isDark),
                  ),

                  const SizedBox(height: 32),
                  
                  Text('6. Data Deletion', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'You retain full ownership of your data. Deleting a document or your account '
                    'permanently removes the associated data from our active databases.',
                    style: _bodyStyle(isDark),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text('7. Policy Updates', style: _headingStyle(isDark)),
                  const SizedBox(height: 12),
                  Text(
                    'We may update this policy occasionally as we add new features. '
                    'We will notify you of any significant changes by updating the date at the top of this document.',
                    style: _bodyStyle(isDark),
                  ),

                  const SizedBox(height: 48),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 48),

                  Text('Disclaimer', style: _headingStyle(isDark).copyWith(fontSize: 24)),
                  const SizedBox(height: 16),
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
