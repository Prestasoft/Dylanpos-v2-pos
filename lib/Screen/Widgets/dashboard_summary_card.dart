import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../currency.dart';

class DashboardSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final String? subtitle;
  final bool isLoading;

  const DashboardSummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.subtitle,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Container(
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Text(
              '$currency ${amount.toStringAsFixed(2).formatNumberWithComma}',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardSummaryGrid extends StatelessWidget {
  final List<DashboardSummaryCard> cards;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const DashboardSummaryGrid({
    Key? key,
    required this.cards,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: 1.5,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }
}

// Pre-defined card configurations for common dashboard metrics
class DashboardCardConfigs {
  static const Color _primaryBlue = Color(0xFF2196F3);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _warningOrange = Color(0xFFFF9800);
  static const Color _errorRed = Color(0xFFf44336);
  static const Color _infoTeal = Color(0xFF009688);
  static const Color _purpleAccent = Color(0xFF9C27B0);

  static DashboardSummaryCard totalFacturado({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Total Facturado',
      amount: amount,
      icon: Icons.receipt_long,
      backgroundColor: _primaryBlue,
      subtitle: 'Ingresos del día',
      isLoading: isLoading,
    );
  }

  static DashboardSummaryCard totalPagado({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Total Pagado',
      amount: amount,
      icon: Icons.check_circle,
      backgroundColor: _successGreen,
      subtitle: 'Pagos recibidos',
      isLoading: isLoading,
    );
  }

  static DashboardSummaryCard totalPendiente({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Total Pendiente',
      amount: amount,
      icon: Icons.pending_actions,
      backgroundColor: _warningOrange,
      subtitle: 'Por cobrar',
      isLoading: isLoading,
    );
  }

  static DashboardSummaryCard pagoEfectivo({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Pago Efectivo',
      amount: amount,
      icon: Icons.money,
      backgroundColor: _successGreen,
      subtitle: 'Cash payments',
      isLoading: isLoading,
    );
  }

  static DashboardSummaryCard pagoTransferencia({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Transferencias',
      amount: amount,
      icon: Icons.account_balance,
      backgroundColor: _infoTeal,
      subtitle: 'Bank transfers',
      isLoading: isLoading,
    );
  }

  static DashboardSummaryCard pagoTarjetas({
    required double amount,
    bool isLoading = false,
  }) {
    return DashboardSummaryCard(
      title: 'Pago Tarjetas',
      amount: amount,
      icon: Icons.credit_card,
      backgroundColor: _purpleAccent,
      subtitle: 'Card payments',
      isLoading: isLoading,
    );
  }
}