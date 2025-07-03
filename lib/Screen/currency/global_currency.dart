import 'package:flutter/material.dart';

class GlobalCurrency extends StatefulWidget {
  const GlobalCurrency({super.key, required this.isDrawer});
  final bool isDrawer;

  @override
  State<GlobalCurrency> createState() => _GlobalCurrencyState();
}

class _GlobalCurrencyState extends State<GlobalCurrency> {
  @override
  void initState() {
    super.initState();
    // Código de inicialización de moneda comentado temporalmente
  }

  @override
  Widget build(BuildContext context) {
    // Botón de selección de moneda comentado temporalmente
    return const SizedBox.shrink();
  }
}
