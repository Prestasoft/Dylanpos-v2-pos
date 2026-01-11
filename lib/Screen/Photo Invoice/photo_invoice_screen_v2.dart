import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/photo_invoice_provider.dart';
import 'package:salespro_admin/Provider/bank_provider.dart';
import 'package:salespro_admin/Repository/photo_invoice_repository.dart';
import 'package:salespro_admin/model/bank_model.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/widgets/customer_search_dialog.dart';
import 'package:salespro_admin/Screen/Photo%20Invoice/widgets/search_product_service_dialog.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf_premium.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf_pro.dart';
import 'package:salespro_admin/PDF/photo_invoice_pdf_simple.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pdf/pdf.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/services/audit_service.dart';
import 'package:salespro_admin/model/audit_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PhotoInvoiceScreenV2 extends ConsumerStatefulWidget {
  const PhotoInvoiceScreenV2({super.key});

  static const String route = '/photo-invoice';

  @override
  ConsumerState<PhotoInvoiceScreenV2> createState() => _PhotoInvoiceScreenV2State();
}

class _PhotoInvoiceScreenV2State extends ConsumerState<PhotoInvoiceScreenV2> with SingleTickerProviderStateMixin {
  final ScrollController mainScroll = ScrollController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController taxController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String selectedPaymentMethod = 'Efectivo';
  String selectedInvoiceFormat = 'standard'; // standard, premium, professional, simple

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    notesController.dispose();
    discountController.dispose();
    taxController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(photoInvoiceProvider);
    final invoiceNotifier = ref.read(photoInvoiceProvider.notifier);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: kDarkWhite),
        child: SingleChildScrollView(
          controller: mainScroll,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header simplificado
                _buildSimpleHeader(),
                const SizedBox(height: 24.0),
                
                // Layout principal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna principal
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _buildCustomerSection(invoiceState, invoiceNotifier),
                          const SizedBox(height: 20.0),
                          _buildItemsSection(invoiceState, invoiceNotifier),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    // Panel lateral
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildPaymentMethodSection(invoiceState, invoiceNotifier),
                          const SizedBox(height: 20.0),
                          _buildSummarySection(invoiceState, invoiceNotifier),
                          const SizedBox(height: 20.0),
                          _buildNotesSection(invoiceNotifier),
                          const SizedBox(height: 20.0),
                          _buildActionButtons(context, invoiceState, invoiceNotifier),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: kMainColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              MdiIcons.cameraImage,
              color: kMainColor,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Factura',
                style: kTextStyle.copyWith(
                  color: kTitleColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Impresión y Enmarcado',
                style: kTextStyle.copyWith(
                  color: kGreyTextColor,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FeatherIcons.calendar, color: kGreyTextColor, size: 16.0),
                const SizedBox(width: 8.0),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: kTextStyle.copyWith(color: kGreyTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.user, color: kTitleColor, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Cliente',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: state.selectedCustomer == null
                ? InkWell(
                    onTap: () async {
                      final customer = await showDialog<CustomerModel>(
                        context: context,
                        builder: (context) => const CustomerSearchDialog(),
                      );
                      if (customer != null) {
                        notifier.setCustomer(customer);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: kBorderColorTextField,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FeatherIcons.userPlus, color: kMainColor, size: 20.0),
                          const SizedBox(width: 8.0),
                          Text(
                            'Seleccionar Cliente',
                            style: kTextStyle.copyWith(
                              color: kMainColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: kMainColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          FeatherIcons.user,
                          color: kMainColor,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.selectedCustomer!.customerName,
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: kTitleColor,
                              ),
                            ),
                            Text(
                              '${state.selectedCustomer!.phoneNumber}',
                              style: kTextStyle.copyWith(
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final customer = await showDialog<CustomerModel>(
                            context: context,
                            builder: (context) => const CustomerSearchDialog(),
                          );
                          if (customer != null) {
                            notifier.setCustomer(customer);
                          }
                        },
                        icon: Icon(FeatherIcons.edit2, size: 16.0, color: kGreyTextColor),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    final allItems = [
      ...state.products.map((p) => {'type': 'product', 'item': p}),
      ...state.services.map((s) => {'type': 'service', 'item': s}),
    ];

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(FeatherIcons.shoppingCart, color: kTitleColor, size: 18.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Items',
                      style: kTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: kTitleColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const SearchProductServiceDialog(),
                    );
                  },
                  icon: Icon(FeatherIcons.plus, size: 14.0),
                  label: Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMainColor,
                    foregroundColor: kWhite,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          allItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(FeatherIcons.inbox, size: 40.0, color: kGreyTextColor.withAlpha(100)),
                        const SizedBox(height: 12.0),
                        Text(
                          'No hay items agregados',
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Header de tabla
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        border: Border(
                          bottom: BorderSide(color: kBorderColorTextField),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Descripción',
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: Text(
                                'Cant.',
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: kGreyTextColor,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Precio',
                              textAlign: TextAlign.right,
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: kGreyTextColor,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    // Items
                    ...allItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final itemData = entry.value;
                      final isProduct = itemData['type'] == 'product';
                      final item = itemData['item'];
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: kBorderColorTextField.withAlpha(50)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color: isProduct ? Colors.orange.withAlpha(20) : Colors.blue.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: Icon(
                                      isProduct ? MdiIcons.imageFrame : MdiIcons.camera,
                                      color: isProduct ? Colors.orange : Colors.blue,
                                      size: 16.0,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isProduct
                                              ? (item as FrameProductModel).productName
                                              : (item as PhotoServiceModel).serviceName,
                                          style: kTextStyle.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: kTitleColor,
                                          ),
                                        ),
                                        if (isProduct && (item as FrameProductModel).size != null)
                                          Text(
                                            item.size!,
                                            style: kTextStyle.copyWith(
                                              color: kGreyTextColor,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                        if (!isProduct && (item as PhotoServiceModel).size != null)
                                          Text(
                                            item.size!,
                                            style: kTextStyle.copyWith(
                                              color: kGreyTextColor,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 120,
                              height: 32,
                              decoration: BoxDecoration(
                                color: kDarkWhite,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Row(
                                children: [
                                  // Botón decrementar
                                  SizedBox(
                                    width: 30,
                                    height: 32,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.remove, size: 16, color: kTitleColor),
                                      onPressed: () {
                                        final currentQty = isProduct
                                            ? (item as FrameProductModel).quantity
                                            : (item as PhotoServiceModel).quantity;
                                        if (currentQty > 1) {
                                          if (isProduct) {
                                            final productIndex = state.products.indexOf(item as FrameProductModel);
                                            notifier.updateProductQuantity(productIndex, currentQty - 1);
                                          } else {
                                            final serviceIndex = state.services.indexOf(item as PhotoServiceModel);
                                            notifier.updateServiceQuantity(serviceIndex, currentQty - 1);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  // Campo de cantidad
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: kMainColor,
                                        borderRadius: BorderRadius.circular(2.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          isProduct
                                              ? (item as FrameProductModel).quantity.toString()
                                              : (item as PhotoServiceModel).quantity.toString(),
                                          style: kTextStyle.copyWith(
                                            fontSize: 14.0,
                                            color: kWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botón incrementar
                                  SizedBox(
                                    width: 30,
                                    height: 32,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add, size: 16, color: kTitleColor),
                                      onPressed: () {
                                        final currentQty = isProduct
                                            ? (item as FrameProductModel).quantity
                                            : (item as PhotoServiceModel).quantity;
                                        if (isProduct) {
                                          final productIndex = state.products.indexOf(item as FrameProductModel);
                                          notifier.updateProductQuantity(productIndex, currentQty + 1);
                                        } else {
                                          final serviceIndex = state.services.indexOf(item as PhotoServiceModel);
                                          notifier.updateServiceQuantity(serviceIndex, currentQty + 1);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                '$currency${isProduct ? (item as FrameProductModel).productPrice.toStringAsFixed(2) : (item as PhotoServiceModel).servicePrice.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: kTextStyle.copyWith(
                                  color: kGreyTextColor,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                '$currency${isProduct ? (item as FrameProductModel).subtotal.toStringAsFixed(2) : (item as PhotoServiceModel).subtotal.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: kTitleColor,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                              onPressed: () {
                                if (isProduct) {
                                  final productIndex = state.products.indexOf(item as FrameProductModel);
                                  notifier.removeProduct(productIndex);
                                } else {
                                  final serviceIndex = state.services.indexOf(item as PhotoServiceModel);
                                  notifier.removeService(serviceIndex);
                                }
                              },
                              icon: Icon(FeatherIcons.trash2, color: Colors.red, size: 16.0),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    final paymentMethods = [
      {'name': 'Efectivo', 'icon': MdiIcons.cash},
      {'name': 'Tarjeta', 'icon': MdiIcons.creditCard},
      {'name': 'Transferencia', 'icon': MdiIcons.bankTransfer},
    ];

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.creditCard, color: kTitleColor, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Método de Pago',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...paymentMethods.map((method) {
                  final isSelected = selectedPaymentMethod == method['name'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = method['name'] as String;
                        });
                        notifier.setPaymentMethod(method['name'] as String);
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isSelected ? kMainColor.withAlpha(20) : kDarkWhite,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected ? kMainColor : kBorderColorTextField,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method['icon'] as IconData,
                              color: isSelected ? kMainColor : kGreyTextColor,
                              size: 20.0,
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              method['name'] as String,
                              style: kTextStyle.copyWith(
                                color: isSelected ? kMainColor : kTitleColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(
                                FeatherIcons.checkCircle,
                                color: kMainColor,
                                size: 18.0,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                // Selector de banco cuando se elija transferencia
                if (selectedPaymentMethod == 'Transferencia') ...[
                  const SizedBox(height: 16.0),
                  Consumer(
                    builder: (context, ref, child) {
                      final banksAsync = ref.watch(allBanksProvider);
                      
                      return banksAsync.when(
                        data: (banks) {
                          final activeBanks = banks.where((b) => b.isActive ?? true).toList();
                          
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: kBorderColorTextField),
                              borderRadius: BorderRadius.circular(8.0),
                              color: kDarkWhite,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: state.selectedBank,
                              decoration: InputDecoration(
                                labelText: 'Seleccionar Banco',
                                labelStyle: kTextStyle.copyWith(color: kTitleColor),
                                hintText: 'Elige un banco',
                                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              ),
                              dropdownColor: kWhite,
                              items: activeBanks.map((bank) {
                                return DropdownMenuItem<String>(
                                  value: bank.bankId,
                                  child: Text(
                                    bank.bankName ?? '',
                                    style: kTextStyle.copyWith(color: kTitleColor),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                notifier.setSelectedBank(value);
                              },
                              validator: (value) {
                                if (selectedPaymentMethod == 'Transferencia' && value == null) {
                                  return 'Por favor selecciona un banco';
                                }
                                return null;
                              },
                            ),
                          );
                        },
                        loading: () => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: kBorderColorTextField),
                            borderRadius: BorderRadius.circular(8.0),
                            color: kDarkWhite,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) => Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: kBorderColorTextField),
                            borderRadius: BorderRadius.circular(8.0),
                            color: kDarkWhite,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error al cargar bancos',
                            style: kTextStyle.copyWith(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.fileText, color: kTitleColor, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Resumen',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal:', state.subtotal),
                const SizedBox(height: 12.0),
                
                // Descuento
                Row(
                  children: [
                    Expanded(child: Text('Descuento:', style: kTextStyle.copyWith(color: kGreyTextColor))),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: kTextStyle.copyWith(fontSize: 13.0, color: kTitleColor),
                        decoration: InputDecoration(
                          prefixText: currency,
                          filled: true,
                          fillColor: kDarkWhite,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0;
                          notifier.setDiscountAmount(amount);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                
                // Impuesto
                Row(
                  children: [
                    Expanded(child: Text('Impuesto:', style: kTextStyle.copyWith(color: kGreyTextColor))),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: taxController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: kTextStyle.copyWith(fontSize: 13.0, color: kTitleColor),
                        decoration: InputDecoration(
                          suffixText: '%',
                          filled: true,
                          fillColor: kDarkWhite,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final rate = double.tryParse(value) ?? 0;
                          notifier.setTaxRate(rate);
                        },
                      ),
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                
                _buildSummaryRow(
                  'TOTAL:',
                  state.totalAmount,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: kMainColor,
                ),
                
                const SizedBox(height: 16.0),
                
                // Monto pagado
                Row(
                  children: [
                    Expanded(child: Text('Pagado:', style: kTextStyle.copyWith(color: kGreyTextColor))),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: paidAmountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: kTextStyle.copyWith(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                        decoration: InputDecoration(
                          prefixText: currency,
                          filled: true,
                          fillColor: Colors.green.withAlpha(10),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0;
                          notifier.setPaidAmount(amount);
                        },
                      ),
                    ),
                  ],
                ),
                
                if (state.dueAmount != 0) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: state.dueAmount > 0 ? Colors.red.withAlpha(10) : Colors.green.withAlpha(10),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.dueAmount > 0 ? 'Pendiente:' : 'Cambio:',
                          style: kTextStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: state.dueAmount > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          '$currency${state.dueAmount.abs().toStringAsFixed(2)}',
                          style: kTextStyle.copyWith(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: state.dueAmount > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notas',
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: kTitleColor,
            ),
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: notesController,
            maxLines: 3,
            style: kTextStyle.copyWith(fontSize: 13.0),
            decoration: InputDecoration(
              hintText: 'Agregar notas...',
              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
              filled: true,
              fillColor: kDarkWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: notifier.setNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    final isValid = state.selectedCustomer != null && (state.products.isNotEmpty || state.services.isNotEmpty);
    
    return Column(
      children: [
        // Selector de formato de factura
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: kBorderColorTextField),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedInvoiceFormat,
              isExpanded: true,
              hint: Text('Formato de factura', style: kTextStyle.copyWith(color: kGreyTextColor)),
              items: [
                DropdownMenuItem(
                  value: 'standard',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: kMainColor),
                      const SizedBox(width: 8),
                      Text('Estándar', style: kTextStyle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'premium',
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Premium', style: kTextStyle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'professional',
                  child: Row(
                    children: [
                      Icon(Icons.business_center, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Profesional', style: kTextStyle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'simple',
                  child: Row(
                    children: [
                      Icon(Icons.text_snippet, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Simple', style: kTextStyle.copyWith(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedInvoiceFormat = value ?? 'standard';
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: double.infinity,
          height: 44.0,
          child: ElevatedButton.icon(
            onPressed: isValid
                ? () async {
                    await _generateAndPrintInvoice(context, state, notifier);
                  }
                : null,
            icon: const Icon(FeatherIcons.printer, size: 16.0),
            label: const Text('Imprimir Factura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kMainColor,
              foregroundColor: kWhite,
              disabledBackgroundColor: kGreyTextColor.withAlpha(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SizedBox(
          width: double.infinity,
          height: 44.0,
          child: OutlinedButton.icon(
            onPressed: () => notifier.clearInvoice(),
            icon: const Icon(FeatherIcons.x, size: 16.0),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kGreyTextColor,
              side: BorderSide(color: kBorderColorTextField),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {double fontSize = 14.0, FontWeight fontWeight = FontWeight.normal, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: kTextStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? kGreyTextColor,
          ),
        ),
        Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: kTextStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? kTitleColor,
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndPrintInvoice(
    BuildContext context,
    PhotoInvoiceState state,
    PhotoInvoiceNotifier notifier,
  ) async {
    print('===== INICIANDO GENERACIÓN DE FACTURA =====');
    try {
      EasyLoading.show(status: 'Generando factura...');
      
      // Validar datos
      if (state.selectedCustomer == null) {
        throw Exception('No se ha seleccionado un cliente');
      }
      
      if (state.products.isEmpty && state.services.isEmpty) {
        throw Exception('No hay productos o servicios en la factura');
      }
      
      // Obtener información personal y configuración
      PersonalInformationModel? personalInfo;
      GeneralSettingModel? generalSetting;
      
      try {
        print('Obteniendo PersonalInformation...');
        personalInfo = await ref.read(profileDetailsProvider.future);
        print('PersonalInformation obtenida: ${personalInfo?.companyName}');
        
        print('Obteniendo GeneralSetting...');
        generalSetting = await ref.read(generalSettingProvider.future);
        print('GeneralSetting obtenida: ${generalSetting?.companyName}');
      } catch (e) {
        print('Error al cargar configuración: $e');
        throw Exception('Error al cargar información de la empresa: $e');
      }
      
      // Generar número de factura
      String invoiceNumber;
      try {
        print('Generando número de factura...');
        invoiceNumber = await notifier.generateInvoiceNumber();
        print('Número de factura generado: $invoiceNumber');
      } catch (e) {
        print('Error al generar número de factura: $e');
        throw Exception('Error al generar número de factura: $e');
      }
      
      // Crear modelo de factura
      PhotoInvoiceModel invoice;
      print('Creando modelo de factura...');
      try {
        print('Customer: ${state.selectedCustomer?.customerName}');
        print('Products: ${state.products.length}');
        print('Services: ${state.services.length}');
        print('Total: ${state.totalAmount}');
        print('Payment Method: $selectedPaymentMethod');
        print('Selected Bank: ${state.selectedBank}');
        print('Paid Amount: ${state.paidAmount}');
        print('Due Amount: ${state.dueAmount}');
        print('Total Amount: ${state.totalAmount}');
        print('Subtotal: ${state.subtotal}');
        print('Tax Rate: ${state.taxRate}');
        
        // Intentar acceder a taxAmount con manejo de error
        double taxAmountValue = 0;
        try {
          taxAmountValue = state.taxAmount;
          print('Tax Amount: $taxAmountValue');
        } catch (e) {
          print('ERROR al calcular taxAmount: $e');
          print('Usando taxAmount = 0');
        }
        
        print('Discount: ${state.discountAmount}');
        
        print('\nCreando PhotoInvoiceModel...');
        try {
          print('  - invoiceNumber: $invoiceNumber');
        } catch (e) {
          print('  - Error al acceder a invoiceNumber: $e');
        }
        print('  - customer name: ${state.selectedCustomer?.customerName}');
        print('  - products count: ${state.products.length}');
        print('  - services count: ${state.services.length}');
        print('  - paymentMethod: $selectedPaymentMethod');
        print('  - selectedBank: ${state.selectedBank}');
        print('  - paymentStatus: ${state.dueAmount > 0 ? "Partial" : "Paid"}');
        
        // Obtener el nombre del banco si es transferencia
        String? selectedBankName;
        if (selectedPaymentMethod == 'Transferencia' && state.selectedBank != null) {
          try {
            final banks = await ref.read(allBanksProvider.future);
            try {
              final selectedBankObj = banks.firstWhere(
                (bank) => bank.bankId == state.selectedBank,
              );
              selectedBankName = selectedBankObj.bankName;
            } catch (_) {
              selectedBankName = state.selectedBank;
            }
            print('Banco seleccionado: $selectedBankName');
          } catch (e) {
            print('Error al obtener nombre del banco: $e');
            selectedBankName = state.selectedBank;
          }
        }
        
        try {
          invoice = PhotoInvoiceModel(
            invoiceNumber: invoiceNumber,
            invoiceDate: DateTime.now(),
            customer: state.selectedCustomer!,
            products: state.products,
            services: state.services,
            discountAmount: state.discountAmount,
            taxRate: state.taxRate,
            taxAmount: taxAmountValue,  // Usar el valor calculado
            notes: state.notes,
            paymentMethod: selectedPaymentMethod,
            selectedBank: selectedBankName ?? state.selectedBank,
            paymentStatus: state.dueAmount > 0 ? 'Partial' : 'Paid',
            paidAmount: state.paidAmount,
            dueAmount: state.dueAmount,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          print('Modelo de factura creado exitosamente');
        } catch (e, st) {
          print('ERROR al crear PhotoInvoiceModel: $e');
          print('Stack trace: $st');
          rethrow;
        }
      } catch (e, stackTrace) {
        print('Error al crear modelo de factura: $e');
        print('Stack trace: $stackTrace');
        throw Exception('Error al crear modelo de factura: $e');
      }
      
      print('Modelo creado, procediendo a guardar en Firebase...');
      
      // Guardar en Firebase (opcional - continuar si falla)
      String? invoiceId;
      try {
        final repository = PhotoInvoiceRepository(userId: personalInfo!.phoneNumber.toString());
        // Agregar timeout de 30 segundos para Firebase (aumentado de 5)
        invoiceId = await repository.saveInvoice(invoice).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('Timeout al guardar en Firebase después de 30 segundos');
            throw Exception('Timeout al guardar en Firebase');
          },
        );
        print('Factura guardada con ID: $invoiceId');
        
        // Registrar en auditoría
        try {
          await AuditService().logCreate(
            module: AuditModule.sales,
            itemName: 'Factura Photo Invoice',
            itemId: invoice.invoiceNumber,
            data: {
              'invoiceNumber': invoice.invoiceNumber,
              'customerName': invoice.customer.customerName,
              'customerPhone': invoice.customer.phoneNumber,
              'totalAmount': invoice.totalAmount,
              'paidAmount': invoice.paidAmount,
              'dueAmount': invoice.dueAmount,
              'isPaid': invoice.isPaid,
              'paymentMethod': invoice.paymentMethod,
              'bankName': invoice.selectedBank,
              'products': invoice.products.map((p) => {
                'name': p.productName,
                'quantity': p.quantity,
                'price': p.productPrice,
                'subtotal': p.subtotal,
              }).toList(),
              'services': invoice.services.map((s) => {
                'name': s.serviceName,
                'quantity': s.quantity,
                'price': s.servicePrice,
                'subtotal': s.subtotal,
              }).toList(),
              'discountAmount': invoice.discountAmount,
              'taxRate': invoice.taxRate,
              'taxAmount': invoice.taxAmount,
            },
          );
        } catch (auditError) {
          print('Error al registrar en auditoría: $auditError');
          // No interrumpir el proceso si falla la auditoría
        }
      } catch (e) {
        print('Error al guardar en Firebase: $e');
        print('Continuando con la generación del PDF sin guardar en Firebase...');
        // Asignar un ID temporal para continuar
        invoiceId = 'TEMP-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Generar PDF
      Uint8List pdfData;
      try {
        print('Iniciando generación de PDF...');
        print('PersonalInfo existe: ${personalInfo != null}');
        if (personalInfo != null) {
          print('PersonalInfo - Company: ${personalInfo.companyName}, Phone: ${personalInfo.phoneNumber}');
        }
        print('GeneralSetting existe: ${generalSetting != null}');
        if (generalSetting != null) {
          print('GeneralSetting - Company: ${generalSetting.companyName}');
        }
        
        if (personalInfo == null) {
          throw Exception('PersonalInformation es null');
        }
        if (generalSetting == null) {
          throw Exception('GeneralSetting es null');
        }
        
        // Usar el generador según el formato seleccionado
        switch (selectedInvoiceFormat) {
          case 'premium':
            pdfData = await generatePremiumPhotoInvoice(
              invoice: invoice,
              personalInformation: personalInfo,
              generalSetting: generalSetting,
            );
            break;
          case 'professional':
            pdfData = await generatePhotoInvoiceDocumentPro(
              invoice: invoice,
              personalInformation: personalInfo,
              generalSetting: generalSetting,
            );
            break;
          case 'simple':
            pdfData = await generateSimplePhotoInvoice(
              invoice: invoice,
              personalInformation: personalInfo,
              generalSetting: generalSetting,
            );
            break;
          case 'standard':
          default:
            pdfData = await generatePhotoInvoiceDocument(
              invoice: invoice,
              personalInformation: personalInfo,
              generalSetting: generalSetting,
            );
            break;
        }
        print('PDF generado exitosamente, tamaño: ${pdfData.length} bytes');
      } catch (e, stackTrace) {
        print('Error al generar PDF: $e');
        print('Stack trace PDF: $stackTrace');
        throw Exception('Error al generar el PDF: $e');
      }
      
      // Imprimir PDF
      try {
        print('Intentando mostrar el PDF para impresión...');
        
        // Intentar primero mostrar el diálogo de impresión
        bool printed = false;
        try {
          printed = await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfData,
            name: 'Factura_$invoiceNumber',
          );
          print('Resultado de layoutPdf: $printed');
        } catch (e) {
          print('Error con layoutPdf: $e');
          // Si layoutPdf falla, intentar con sharePdf
          if (kIsWeb) {
            print('Intentando con sharePdf...');
            await Printing.sharePdf(
              bytes: pdfData,
              filename: 'Factura_$invoiceNumber.pdf',
            );
            printed = true;
          }
        }
        
        if (!printed) {
          print('El usuario canceló la impresión, ofreciendo descarga directa...');
          await Printing.sharePdf(
            bytes: pdfData,
            filename: 'Factura_$invoiceNumber.pdf',
          );
        }
        
        print('PDF mostrado/descargado exitosamente');
      } catch (e) {
        print('Error al mostrar el PDF: $e');
        
        // Como última alternativa, crear un blob URL para descarga directa
        if (kIsWeb) {
          try {
            print('Intentando descarga directa con Blob URL...');
            final blob = html.Blob([pdfData], 'application/pdf');
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement()
              ..href = url
              ..download = 'Factura_$invoiceNumber.pdf'
              ..click();
            html.Url.revokeObjectUrl(url);
            print('PDF descargado exitosamente con Blob URL');
          } catch (e2) {
            print('Error al descargar con Blob URL: $e2');
            throw Exception('Error al descargar el PDF: $e2');
          }
        } else {
          throw Exception('Error al imprimir/descargar el PDF: $e');
        }
      }
      
      // Registrar impresión en auditoría
      try {
        await AuditService().logPrint(
          module: AuditModule.sales,
          documentType: 'Factura Photo Invoice',
          documentId: invoice.invoiceNumber,
        );
      } catch (auditError) {
        print('Error al registrar impresión en auditoría: $auditError');
      }
      
      EasyLoading.dismiss();
      toast('Factura generada exitosamente');
      
      // Limpiar formulario
      notifier.clearInvoice();
      
    } catch (e, stackTrace) {
      EasyLoading.dismiss();
      print('Error detallado: $e');
      print('Stack trace: $stackTrace');
      
      // Mostrar error más específico
      String errorMessage = 'Error al generar la factura';
      if (e.toString().contains('personalInformation')) {
        errorMessage = 'Error: No se pudo cargar la información de la empresa';
      } else if (e.toString().contains('customer')) {
        errorMessage = 'Error: Información del cliente incompleta';
      } else if (e.toString().contains('PDF')) {
        errorMessage = 'Error: No se pudo generar el PDF';
      } else if (e.toString().contains('Firebase')) {
        errorMessage = 'Error: No se pudo guardar en la base de datos';
      }
      
      toast('$errorMessage: ${e.toString()}');
    }
  }
}