import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/Provider/photo_invoice_provider.dart';
import 'package:salespro_admin/Screen/Widgets/Constant%20Data/constant.dart';
import 'package:salespro_admin/currency.dart';
import 'package:salespro_admin/model/customer_model.dart';
import 'package:salespro_admin/model/frame_product_model.dart';
import 'package:salespro_admin/model/photo_service_model.dart';
import 'package:salespro_admin/model/photo_invoice_model.dart';
import 'package:salespro_admin/Provider/profile_provider.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/model/personal_information_model.dart';
import 'package:salespro_admin/model/general_setting_model.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:salespro_admin/const.dart';
import 'package:salespro_admin/model/sale_transaction_model.dart';
import 'package:salespro_admin/model/add_to_cart_model.dart';
import 'package:salespro_admin/PDF/print_pdf.dart';
import 'package:salespro_admin/Repository/photo_invoice_repository.dart';

class PhotoInvoiceScreen extends ConsumerStatefulWidget {
  const PhotoInvoiceScreen({super.key});

  static const String route = '/photo-invoice';

  @override
  ConsumerState<PhotoInvoiceScreen> createState() => _PhotoInvoiceScreenState();
}

class _PhotoInvoiceScreenState extends ConsumerState<PhotoInvoiceScreen> with SingleTickerProviderStateMixin {
  final ScrollController mainScroll = ScrollController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController taxController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    final availableProducts = ref.watch(availableFrameProductsProvider);
    final availableServices = ref.watch(availablePhotoServicesProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kDarkWhite,
              kDarkWhite.withAlpha(240),
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: mainScroll,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con título e iconos
                _buildHeader(),
                const SizedBox(height: 32.0),
                
                // Grid layout para mejor organización
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1200) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna principal (izquierda)
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                _buildCustomerCard(invoiceState, invoiceNotifier),
                                const SizedBox(height: 24.0),
                                _buildProductsCard(invoiceState, invoiceNotifier, availableProducts),
                                const SizedBox(height: 24.0),
                                _buildServicesCard(invoiceState, invoiceNotifier, availableServices),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24.0),
                          // Columna lateral (derecha)
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildInvoiceSummaryCard(invoiceState, invoiceNotifier),
                                const SizedBox(height: 24.0),
                                _buildNotesCard(invoiceNotifier),
                                const SizedBox(height: 24.0),
                                _buildActionsCard(context, invoiceState, invoiceNotifier),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Vista móvil/tablet
                      return Column(
                        children: [
                          _buildCustomerCard(invoiceState, invoiceNotifier),
                          const SizedBox(height: 24.0),
                          _buildProductsCard(invoiceState, invoiceNotifier, availableProducts),
                          const SizedBox(height: 24.0),
                          _buildServicesCard(invoiceState, invoiceNotifier, availableServices),
                          const SizedBox(height: 24.0),
                          _buildInvoiceSummaryCard(invoiceState, invoiceNotifier),
                          const SizedBox(height: 24.0),
                          _buildNotesCard(invoiceNotifier),
                          const SizedBox(height: 24.0),
                          _buildActionsCard(context, invoiceState, invoiceNotifier),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColor, kMainColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: kWhite.withAlpha(30),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              MdiIcons.cameraImage,
              color: kWhite,
              size: 32.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva Factura - Impresión y Enmarcado',
                  style: kTextStyle.copyWith(
                    color: kWhite,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Gestiona servicios de fotografía y productos de enmarcado',
                  style: kTextStyle.copyWith(
                    color: kWhite.withAlpha(200),
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: kWhite.withAlpha(30),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FeatherIcons.calendar, color: kWhite, size: 16.0),
                const SizedBox(width: 8.0),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: kTextStyle.copyWith(color: kWhite, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: kMainColor.withAlpha(10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.user, color: kMainColor, size: 20.0),
                const SizedBox(width: 12.0),
                Text(
                  'Información del Cliente',
                  style: kTextStyle.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: state.selectedCustomer == null
                ? InkWell(
                    onTap: () async {
                      final customer = await _selectCustomer();
                      if (customer != null) {
                        notifier.setCustomer(customer);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: kMainColor.withAlpha(10),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: kMainColor.withAlpha(50),
                          width: 2.0,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FeatherIcons.userPlus, color: kMainColor, size: 24.0),
                          const SizedBox(width: 12.0),
                          Text(
                            'Seleccionar Cliente',
                            style: kTextStyle.copyWith(
                              color: kMainColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kMainColor.withAlpha(5),
                          kMainColor.withAlpha(10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: kMainColor.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: kMainColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FeatherIcons.user,
                            color: kMainColor,
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.selectedCustomer!.customerName,
                                style: kTextStyle.copyWith(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: kTitleColor,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  Icon(FeatherIcons.phone, size: 14.0, color: kGreyTextColor),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    state.selectedCustomer!.phoneNumber,
                                    style: kTextStyle.copyWith(
                                      color: kGreyTextColor,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  if (state.selectedCustomer!.emailAddress.isNotEmpty) ...[
                                    const SizedBox(width: 16.0),
                                    Icon(FeatherIcons.mail, size: 14.0, color: kGreyTextColor),
                                    const SizedBox(width: 6.0),
                                    Expanded(
                                      child: Text(
                                        state.selectedCustomer!.emailAddress,
                                        style: kTextStyle.copyWith(
                                          color: kGreyTextColor,
                                          fontSize: 14.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final customer = await _selectCustomer();
                            if (customer != null) {
                              notifier.setCustomer(customer);
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: kMainColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(FeatherIcons.edit3, size: 16.0, color: kMainColor),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(
    PhotoInvoiceState state,
    PhotoInvoiceNotifier notifier,
    List<FrameProductModel> availableProducts,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withAlpha(20),
                  Colors.orange.withAlpha(10),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(MdiIcons.imageFrame, color: Colors.orange, size: 20.0),
                    const SizedBox(width: 12.0),
                    Text(
                      'Productos de Enmarcado',
                      style: kTextStyle.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: kTitleColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(availableProducts, notifier),
                  icon: const Icon(FeatherIcons.plus, size: 16.0),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          state.products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(MdiIcons.imageFrame, size: 48.0, color: kGreyTextColor.withAlpha(100)),
                        const SizedBox(height: 16.0),
                        Text(
                          'No hay productos agregados',
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: state.products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.orange.withAlpha(30)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(20),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(MdiIcons.imageFrame, color: Colors.orange, size: 20.0),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: kTextStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    '${product.size ?? ''} ${product.material ?? ''} ${product.color ?? ''}'.trim(),
                                    style: kTextStyle.copyWith(
                                      color: kGreyTextColor,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: product.quantity.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: kTextStyle.copyWith(fontSize: 14.0),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: kWhite,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(color: kBorderColorTextField),
                                  ),
                                ),
                                onChanged: (value) {
                                  final qty = int.tryParse(value) ?? 0;
                                  notifier.updateProductQuantity(index, qty);
                                },
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currency${product.productPrice.toStringAsFixed(2)}',
                                  style: kTextStyle.copyWith(
                                    color: kGreyTextColor,
                                    fontSize: 14.0,
                                  ),
                                ),
                                Text(
                                  '$currency${product.subtotal.toStringAsFixed(2)}',
                                  style: kTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16.0),
                            IconButton(
                              onPressed: () => notifier.removeProduct(index),
                              icon: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Icon(FeatherIcons.trash2, color: Colors.red, size: 16.0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(
    PhotoInvoiceState state,
    PhotoInvoiceNotifier notifier,
    List<PhotoServiceModel> availableServices,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withAlpha(20),
                  Colors.blue.withAlpha(10),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(MdiIcons.camera, color: Colors.blue, size: 20.0),
                    const SizedBox(width: 12.0),
                    Text(
                      'Servicios de Impresión',
                      style: kTextStyle.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: kTitleColor,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showServiceDialog(availableServices, notifier),
                  icon: const Icon(FeatherIcons.plus, size: 16.0),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: kWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          state.services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(MdiIcons.cameraOutline, size: 48.0, color: kGreyTextColor.withAlpha(100)),
                        const SizedBox(height: 16.0),
                        Text(
                          'No hay servicios agregados',
                          style: kTextStyle.copyWith(color: kGreyTextColor),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: state.services.asMap().entries.map((entry) {
                      final index = entry.key;
                      final service = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.blue.withAlpha(30)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(20),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(MdiIcons.camera, color: Colors.blue, size: 20.0),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.serviceName,
                                    style: kTextStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    service.size ?? service.serviceType,
                                    style: kTextStyle.copyWith(
                                      color: kGreyTextColor,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: service.quantity.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: kTextStyle.copyWith(fontSize: 14.0),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: kWhite,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(color: kBorderColorTextField),
                                  ),
                                ),
                                onChanged: (value) {
                                  final qty = int.tryParse(value) ?? 0;
                                  notifier.updateServiceQuantity(index, qty);
                                },
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currency${service.servicePrice.toStringAsFixed(2)}',
                                  style: kTextStyle.copyWith(
                                    color: kGreyTextColor,
                                    fontSize: 14.0,
                                  ),
                                ),
                                Text(
                                  '$currency${service.subtotal.toStringAsFixed(2)}',
                                  style: kTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16.0),
                            IconButton(
                              onPressed: () => notifier.removeService(index),
                              icon: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Icon(FeatherIcons.trash2, color: Colors.red, size: 16.0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummaryCard(PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColor.withAlpha(10), kMainColor.withAlpha(5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kMainColor.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: kMainColor.withAlpha(20),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.dollarSign, color: kMainColor, size: 20.0),
                const SizedBox(width: 12.0),
                Text(
                  'Resumen de Factura',
                  style: kTextStyle.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal Productos:', state.productSubtotal, Colors.orange),
                const SizedBox(height: 12.0),
                _buildSummaryRow('Subtotal Servicios:', state.serviceSubtotal, Colors.blue),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(),
                ),
                _buildSummaryRow('Subtotal:', state.subtotal),
                const SizedBox(height: 16.0),
                
                // Descuento
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.tag, size: 16.0, color: kGreyTextColor),
                      const SizedBox(width: 8.0),
                      Expanded(child: Text('Descuento:')),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: kTextStyle.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            prefixText: currency,
                            filled: true,
                            fillColor: kDarkWhite,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                ),
                const SizedBox(height: 12.0),
                
                // Impuesto
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.percent, size: 16.0, color: kGreyTextColor),
                      const SizedBox(width: 8.0),
                      Expanded(child: Text('Impuesto:')),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: taxController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: kTextStyle.copyWith(fontSize: 14.0, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            suffixText: '%',
                            filled: true,
                            fillColor: kDarkWhite,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(thickness: 2),
                ),
                
                _buildSummaryRow(
                  'TOTAL:',
                  state.totalAmount,
                  kMainColor,
                  20.0,
                  FontWeight.bold,
                ),
                
                const SizedBox(height: 20.0),
                
                // Monto pagado
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(10),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.green.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.dollarSign, size: 16.0, color: Colors.green),
                      const SizedBox(width: 8.0),
                      Expanded(child: Text('Monto Pagado:')),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: paidAmountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: kTextStyle.copyWith(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                          decoration: InputDecoration(
                            prefixText: currency,
                            filled: true,
                            fillColor: Colors.green.withAlpha(10),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                ),
                
                if (state.dueAmount != 0) ...[
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: state.dueAmount > 0 ? Colors.red.withAlpha(10) : Colors.green.withAlpha(10),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: state.dueAmount > 0 ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              state.dueAmount > 0 ? FeatherIcons.alertCircle : FeatherIcons.checkCircle,
                              size: 16.0,
                              color: state.dueAmount > 0 ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              state.dueAmount > 0 ? 'Monto Pendiente:' : 'Cambio:',
                              style: kTextStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Widget _buildNotesCard(PhotoInvoiceNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.fileText, color: kGreyTextColor, size: 20.0),
                const SizedBox(width: 12.0),
                Text(
                  'Notas',
                  style: kTextStyle.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              controller: notesController,
              maxLines: 4,
              style: kTextStyle.copyWith(fontSize: 14.0),
              decoration: InputDecoration(
                hintText: 'Agregar notas o instrucciones especiales...',
                hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                filled: true,
                fillColor: kDarkWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: notifier.setNotes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, PhotoInvoiceState state, PhotoInvoiceNotifier notifier) {
    final isValid = state.selectedCustomer != null && (state.products.isNotEmpty || state.services.isNotEmpty);
    
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton.icon(
              onPressed: isValid
                  ? () async {
                      await _generateAndPrintInvoice(context, state, notifier);
                    }
                  : null,
              icon: const Icon(FeatherIcons.printer),
              label: const Text('Generar e Imprimir Factura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: kWhite,
                disabledBackgroundColor: kGreyTextColor.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: OutlinedButton.icon(
              onPressed: () => notifier.clearInvoice(),
              icon: const Icon(FeatherIcons.x),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kGreyTextColor,
                side: BorderSide(color: kBorderColorTextField),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, [Color? color, double fontSize = 14.0, FontWeight fontWeight = FontWeight.normal]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: kTextStyle.copyWith(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color ?? kTitleColor,
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

  Future<CustomerModel?> _selectCustomer() async {
    return await showDialog<CustomerModel>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: 600,
          height: 600,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seleccionar Cliente',
                    style: kTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(FeatherIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final customers = ref.watch(allCustomerProvider);
                    return customers.when(
                      data: (customerList) => ListView.builder(
                        itemCount: customerList.length,
                        itemBuilder: (context, index) {
                          final customer = customerList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              color: kDarkWhite,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: kBorderColorTextField),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kMainColor.withAlpha(20),
                                child: Icon(FeatherIcons.user, color: kMainColor, size: 20.0),
                              ),
                              title: Text(
                                customer.customerName,
                                style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(customer.phoneNumber),
                              trailing: Icon(FeatherIcons.chevronRight, color: kMainColor),
                              onTap: () => Navigator.pop(context, customer),
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDialog(List<FrameProductModel> products, PhotoInvoiceNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(MdiIcons.imageFrame, color: Colors.orange, size: 24.0),
                      const SizedBox(width: 12.0),
                      Text(
                        'Agregar Producto',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(FeatherIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ...products.map((product) => Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(5),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.orange.withAlpha(30)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(20),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(MdiIcons.imageFrame, color: Colors.orange),
                      ),
                      title: Text(
                        product.productName,
                        style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${product.size} - $currency${product.productPrice}'),
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: kMainColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
                        ),
                        onPressed: () {
                          notifier.addProduct(product);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceDialog(List<PhotoServiceModel> services, PhotoInvoiceNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(MdiIcons.camera, color: Colors.blue, size: 24.0),
                      const SizedBox(width: 12.0),
                      Text(
                        'Agregar Servicio',
                        style: kTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(FeatherIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ...services.map((service) => Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(5),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withAlpha(30)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(MdiIcons.camera, color: Colors.blue),
                      ),
                      title: Text(
                        service.serviceName,
                        style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${service.size ?? service.serviceType} - $currency${service.servicePrice}'),
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: kMainColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(FeatherIcons.plus, color: kWhite, size: 16.0),
                        ),
                        onPressed: () {
                          notifier.addService(service);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndPrintInvoice(
    BuildContext context,
    PhotoInvoiceState state,
    PhotoInvoiceNotifier notifier,
  ) async {
    try {
      EasyLoading.show(status: 'Generando factura...');
      
      // Ejecutar operaciones independientes en paralelo
      final results = await Future.wait([
        ref.read(profileDetailsProvider.future),
        ref.read(generalSettingProvider.future),
        notifier.generateInvoiceNumber(),
      ]);
      
      final personalInfo = results[0] as PersonalInformationModel;
      final generalSetting = results[1] as GeneralSettingModel;
      final invoiceNumber = results[2] as String;
      
      // Nota: Ya no necesitamos crear el modelo PhotoInvoiceModel aquí
      // El PDF se generará usando GeneratePdfAndPrint después de guardar
      String? pdfUrl;
      
      // Convertir productos y servicios a formato de carrito usando map para mejor rendimiento
      final productList = [
        ...state.products.map((product) => AddToCartModel(
          productName: product.productName,
          productId: product.productId ?? '',
          productImage: '',
          productPurchasePrice: product.productPrice,
          subTotal: product.subtotal.toString(),
          serialNumber: [],
          quantity: product.quantity,
          productBrandName: '',
          groupTaxName: 'N/A',
          groupTaxRate: 0,
          subTaxes: [],
          taxType: 'Exclusive',
          warehouseName: 'Main Warehouse',
          warehouseId: 'main',
          margin: 0,
          excTax: 0,
          incTax: 0,
        )),
        ...state.services.map((service) => AddToCartModel(
          productName: service.serviceName,
          productId: service.serviceId ?? '',
          productImage: '',
          productPurchasePrice: service.servicePrice,
          subTotal: service.subtotal.toString(),
          serialNumber: [],
          quantity: service.quantity,
          productBrandName: '',
          groupTaxName: 'N/A',
          groupTaxRate: 0,
          subTaxes: [],
          taxType: 'Exclusive',
          warehouseName: 'Main Warehouse',
          warehouseId: 'main',
          margin: 0,
          excTax: 0,
          incTax: 0,
        )),
      ];
      
      // Cachear referencia al cliente para evitar accesos múltiples
      final customer = state.selectedCustomer!;
      
      // Calcular cantidad total durante la conversión para evitar otra iteración
      final totalQuantity = state.products.fold<int>(0, (sum, p) => sum + p.quantity) +
                           state.services.fold<int>(0, (sum, s) => sum + s.quantity);
      
      // El PDF se generará después de guardar
      // String? pdfUrl = null; // Ya está definido arriba
      
      // Crear el modelo de transacción de venta
      final saleTransaction = SaleTransactionModel(
        customerName: customer.customerName,
        customerPhone: customer.phoneNumber,
        customerType: customer.type,
        invoiceNumber: invoiceNumber,
        purchaseDate: DateTime.now().toString(),
        productList: productList,
        totalQuantity: totalQuantity,
        totalAmount: state.totalAmount,
        discountAmount: state.discountAmount,
        vat: state.taxAmount,
        isPaid: state.dueAmount <= 0,
        paymentType: state.paymentMethod,
        lossProfit: 0,
        sellerName: constSubUserTitle.isNotEmpty ? constSubUserTitle : 'Admin',
        dueAmount: state.dueAmount,
        returnAmount: 0,
        serviceCharge: 0,
        saleType: 'Photo Invoice',
        reservationIds: [],
        pdfUrl: pdfUrl,
        bankName: state.selectedBank ?? 'N/A',
        customerAddress: customer.customerAddress,
        customerImage: customer.profilePicture,
        customerGst: customer.gst,
      );
      
      // Calcular loss/profit
      final updatedTransaction = checkLossProfit(transitionModel: saleTransaction);
      
      // Crear PhotoInvoiceModel para guardar en la nueva estructura
      final photoInvoice = PhotoInvoiceModel(
        invoiceNumber: invoiceNumber,
        customer: customer,
        products: state.products,
        services: state.services,
        discountAmount: state.discountAmount,
        taxRate: state.taxAmount > 0 ? (state.taxAmount / state.subtotal * 100) : 0,
        taxAmount: state.taxAmount,
        paymentMethod: state.paymentMethod,
        selectedBank: state.selectedBank,
        paymentStatus: state.dueAmount <= 0 ? 'Paid' : 'Partial',
        paidAmount: state.paidAmount,
        dueAmount: state.dueAmount,
        invoiceDate: DateTime.now(),
        notes: state.notes,
        pdfUrl: pdfUrl,
      );
      
      // Guardar en Firebase Realtime Database usando PhotoInvoiceRepository
      // IMPORTANTE: Usar siempre personalInfo.phoneNumber para consistencia
      String userIdToUse = personalInfo.phoneNumber;
      print('Guardando factura con userId: $userIdToUse');
      print('NOTA: Usando phoneNumber para consistencia con facturas existentes');
      
      final repository = PhotoInvoiceRepository(userId: userIdToUse);
      
      String savedInvoiceId = '';
      try {
        savedInvoiceId = await repository.saveInvoice(photoInvoice);
        print('Factura guardada con ID: $savedInvoiceId');
        
        if (savedInvoiceId.isEmpty) {
          throw Exception('No se pudo obtener el ID de la factura guardada');
        }
      } catch (saveError) {
        print('ERROR al guardar la factura: $saveError');
        toast('Error al guardar la factura: $saveError');
        EasyLoading.dismiss();
        return;
      }
      
      // Usar GeneratePdfAndPrint para imprimir la factura
      if (mounted) {
        await GeneratePdfAndPrint().printSaleInvoice(
          personalInformationModel: personalInfo,
          saleTransactionModel: updatedTransaction,
          context: context,
          setting: generalSetting,
          fromInventorySale: true,
        );
      }
      
      EasyLoading.dismiss();
      toast('Factura generada y guardada exitosamente');
      notifier.clearInvoice();
      
    } catch (e) {
      EasyLoading.dismiss();
      toast('Error al generar la factura: $e');
    }
  }
}