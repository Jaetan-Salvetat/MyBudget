import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialSummaryCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Color primaryColor;
  final double amount;
  final String? trendLabel;
  final IconData trendIcon;
  final int? itemCount;
  final Widget? childContent;
  final NumberFormat? formatter;
  final bool isPositive;
  
  const FinancialSummaryCard({
    required this.title,
    required this.titleIcon,
    required this.primaryColor,
    required this.amount,
    this.trendLabel,
    required this.trendIcon,
    this.itemCount,
    this.childContent,
    this.formatter,
    this.isPositive = true,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final actualFormatter = formatter ?? 
        NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildHeaderSection(context, actualFormatter),
          if (childContent != null)
            childContent!
          else
            const SizedBox.shrink()
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection(BuildContext context, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.05),
            primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  titleIcon,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (itemCount != null || trendLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendIcon,
                        color: primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trendLabel ?? itemCount.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
