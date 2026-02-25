import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salespro_admin/services/api_service.dart';

/// Modelo para la tasa de cambio
class ExchangeRate {
  final String id;
  final String currencyFrom;
  final String currencyTo;
  final double buyRate;
  final double sellRate;
  final String source;
  final DateTime sourceDate;
  final DateTime fetchedAt;
  final double rate; // Tasa de venta (la más usada para facturación)

  ExchangeRate({
    required this.id,
    required this.currencyFrom,
    required this.currencyTo,
    required this.buyRate,
    required this.sellRate,
    required this.source,
    required this.sourceDate,
    required this.fetchedAt,
    required this.rate,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: json['id'] ?? '',
      currencyFrom: json['currencyFrom'] ?? 'USD',
      currencyTo: json['currencyTo'] ?? 'DOP',
      buyRate: (json['buyRate'] ?? 0).toDouble(),
      sellRate: (json['sellRate'] ?? 0).toDouble(),
      source: json['source'] ?? 'BCRD',
      sourceDate: json['sourceDate'] != null
          ? DateTime.parse(json['sourceDate'].toString().split('T')[0])
          : DateTime.now(),
      fetchedAt: json['fetchedAt'] != null
          ? DateTime.parse(json['fetchedAt'].toString())
          : DateTime.now(),
      rate: (json['rate'] ?? json['sellRate'] ?? 0).toDouble(),
    );
  }

  /// Convertir DOP a USD
  double dopToUsd(double amountDOP) {
    if (sellRate <= 0) return 0;
    return amountDOP / sellRate;
  }

  /// Convertir USD a DOP
  double usdToDop(double amountUSD) {
    return amountUSD * sellRate;
  }

  /// Formato de la tasa para mostrar
  String get rateFormatted => 'RD\$${sellRate.toStringAsFixed(2)}';

  /// Descripción completa de la tasa
  String get description => '1 USD = RD\$${sellRate.toStringAsFixed(2)} ($source ${sourceDate.day}/${sourceDate.month}/${sourceDate.year})';
}

/// Instancia del ApiService
final _apiService = ApiService();

/// Provider para obtener la tasa de cambio actual
final exchangeRateProvider = FutureProvider<ExchangeRate?>((ref) async {
  try {
    debugPrint('🔄 [exchangeRateProvider] Obteniendo tasa de cambio...');

    final response = await _apiService.get('exchange-rate');

    if (response.success && response.data != null) {
      final data = response.data['data'] ?? response.data;
      final rate = ExchangeRate.fromJson(data);

      debugPrint('✅ [exchangeRateProvider] Tasa obtenida: ${rate.description}');
      return rate;
    } else {
      debugPrint('⚠️ [exchangeRateProvider] No se pudo obtener tasa: ${response.error}');
      return null;
    }
  } catch (e) {
    debugPrint('❌ [exchangeRateProvider] Error: $e');
    return null;
  }
});

/// Provider para el historial de tasas
final exchangeRateHistoryProvider = FutureProvider.family<List<ExchangeRate>, int>((ref, days) async {
  try {
    final response = await _apiService.get('exchange-rate/history', queryParams: {'days': days.toString()});

    if (response.success && response.data != null) {
      final List<dynamic> dataList = response.data['data'] ?? [];
      return dataList.map((json) => ExchangeRate.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    debugPrint('❌ [exchangeRateHistoryProvider] Error: $e');
    return [];
  }
});

/// Provider para convertir montos
final convertCurrencyProvider = FutureProvider.family<Map<String, dynamic>?, Map<String, dynamic>>((ref, params) async {
  try {
    final amount = params['amount'];
    final from = params['from'] ?? 'DOP';
    final to = params['to'] ?? 'USD';

    final response = await _apiService.get('exchange-rate/convert', queryParams: {
      'amount': amount.toString(),
      'from': from,
      'to': to,
    });

    if (response.success && response.data != null) {
      return response.data['data'];
    }
    return null;
  } catch (e) {
    debugPrint('❌ [convertCurrencyProvider] Error: $e');
    return null;
  }
});

/// Provider para la moneda seleccionada actualmente
final selectedCurrencyProvider = StateProvider<String>((ref) => 'DOP');

/// Enum para las monedas soportadas
// ignore: constant_identifier_names
enum Currency {
  // ignore: constant_identifier_names
  DOP,
  // ignore: constant_identifier_names
  USD;

  String get symbol {
    switch (this) {
      case Currency.DOP:
        return 'RD\$';
      case Currency.USD:
        return '\$';
    }
  }

  String get name {
    switch (this) {
      case Currency.DOP:
        return 'Peso Dominicano';
      case Currency.USD:
        return 'Dólar Estadounidense';
    }
  }

  String get code {
    switch (this) {
      case Currency.DOP:
        return 'DOP';
      case Currency.USD:
        return 'USD';
    }
  }
}

/// Extension para formatear montos con moneda
extension CurrencyFormatExtension on double {
  String formatAsDOP() {
    return 'RD\$${toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String formatAsUSD() {
    return '\$${toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String formatAsCurrency(String currencyCode) {
    if (currencyCode == 'USD') {
      return formatAsUSD();
    }
    return formatAsDOP();
  }
}