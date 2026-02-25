import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/Provider/exchange_rate_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';

/// Widget para seleccionar la moneda de facturación (DOP/USD)
/// Muestra la tasa de cambio actual del BCRD
class CurrencySelectorWidget extends ConsumerWidget {
  final String selectedCurrency;
  final Function(String) onCurrencyChanged;
  final bool showRate;
  final bool compact;

  const CurrencySelectorWidget({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    this.showRate = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateAsync = ref.watch(exchangeRateProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kNeutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de moneda
          _buildCurrencyButton('DOP', 'RD\$', selectedCurrency == 'DOP'),
          const SizedBox(width: 4),
          _buildCurrencyButton('USD', '\$', selectedCurrency == 'USD'),

          // Mostrar tasa de cambio si está habilitado
          if (showRate) ...[
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 24,
              color: kNeutral300,
            ),
            const SizedBox(width: 12),
            exchangeRateAsync.when(
              data: (rate) {
                if (rate == null) {
                  return const Text(
                    'Sin tasa',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '1 USD = RD\$${rate.sellRate.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kTitleColor,
                      ),
                    ),
                    Text(
                      '${rate.source} ${rate.sourceDate.day}/${rate.sourceDate.month}',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text(
                'Error',
                style: TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyButton(String code, String symbol, bool isSelected) {
    return InkWell(
      onTap: () => onCurrencyChanged(code),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? kMainColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? kMainColor : kNeutral300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? kWhite : kTitleColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              code,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: isSelected ? kWhite : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar un monto con conversión automática
class CurrencyAmountWidget extends ConsumerWidget {
  final double amountDOP;
  final String displayCurrency;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final bool showBothCurrencies;

  const CurrencyAmountWidget({
    super.key,
    required this.amountDOP,
    required this.displayCurrency,
    this.primaryStyle,
    this.secondaryStyle,
    this.showBothCurrencies = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateAsync = ref.watch(exchangeRateProvider);

    return exchangeRateAsync.when(
      data: (rate) {
        if (rate == null) {
          // Sin tasa, mostrar solo en DOP
          return Text(
            'RD\$${amountDOP.toStringAsFixed(2)}',
            style: primaryStyle ?? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        final amountUSD = rate.dopToUsd(amountDOP);

        if (displayCurrency == 'USD') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${amountUSD.toStringAsFixed(2)} USD',
                style: primaryStyle ?? const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showBothCurrencies)
                Text(
                  'RD\$${amountDOP.toStringAsFixed(2)} @ ${rate.sellRate.toStringAsFixed(2)}',
                  style: secondaryStyle ?? const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RD\$${amountDOP.toStringAsFixed(2)}',
                style: primaryStyle ?? const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showBothCurrencies)
                Text(
                  '\$${amountUSD.toStringAsFixed(2)} USD @ ${rate.sellRate.toStringAsFixed(2)}',
                  style: secondaryStyle ?? const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          );
        }
      },
      loading: () => Text(
        'RD\$${amountDOP.toStringAsFixed(2)}',
        style: primaryStyle,
      ),
      error: (_, __) => Text(
        'RD\$${amountDOP.toStringAsFixed(2)}',
        style: primaryStyle,
      ),
    );
  }
}

/// Widget para mostrar la tasa de cambio actual de forma compacta
class ExchangeRateBadge extends ConsumerWidget {
  final bool showSource;

  const ExchangeRateBadge({
    super.key,
    this.showSource = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRateAsync = ref.watch(exchangeRateProvider);

    return exchangeRateAsync.when(
      data: (rate) {
        if (rate == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Sin tasa USD',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.currency_exchange, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                '1 USD = RD\$${rate.sellRate.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              if (showSource) ...[
                const SizedBox(width: 4),
                Text(
                  '(${rate.source})',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.green.shade400,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 4),
            Text(
              'Cargando tasa...',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'Error tasa',
              style: TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}