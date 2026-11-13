import 'package:flutter/material.dart';
import 'package:openvalut/l10n-generated/app_localizations.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class OtpFieldEntryEditor extends StatelessWidget {
  const OtpFieldEntryEditor({
    super.key,
    required this.otpCode,
    required this.elapsed,
    required this.period,
  });

  final String otpCode;
  final int elapsed;
  final int period;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final remaining = period - elapsed;
    final progressColor = remaining < 10
        ? Colors.red
        : remaining < 40
        ? Colors.orange
        : Colors.green;
    return StreamBuilder(
      stream: Stream<void>.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return InputDecorator(
          decoration: InputDecoration(
            filled: true,
            labelText: loc.otpEntryLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    otpCode,
                    textAlign: TextAlign.left,
                    style:
                        theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                  ),
                ),
                CircularPercentIndicator(
                  radius: 28.0,
                  lineWidth: 4.0,
                  percent: 1 - (elapsed / period.toDouble()),
                  backgroundColor: Colors.black12,
                  progressColor: progressColor,
                  center: Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: progressColor,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
