import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../Provider/customer_provider.dart';
import '../../../../model/customer_model.dart';
import '../../../../services/api_service.dart';
import '../../Constant Data/constant.dart';

/// Popup para crear un nuevo proveedor (Supplier) - Usa PostgreSQL API
class PurchaseCreateCustomerPopUp extends StatefulWidget {
  const PurchaseCreateCustomerPopUp({Key? key}) : super(key: key);

  @override
  State<PurchaseCreateCustomerPopUp> createState() => _PurchaseCreateCustomerPopUpState();
}

class _PurchaseCreateCustomerPopUpState extends State<PurchaseCreateCustomerPopUp> {
  List<String> supplierType = [
    'Supplier',
  ];
  String selectedSupplierType = 'Supplier';

  final TextEditingController supplierNameController = TextEditingController();
  final TextEditingController previousDueController = TextEditingController();
  final TextEditingController supplierPhoneController = TextEditingController();
  final TextEditingController supplierEmailController = TextEditingController();
  final TextEditingController supplierAddressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    supplierNameController.dispose();
    previousDueController.dispose();
    supplierPhoneController.dispose();
    supplierEmailController.dispose();
    supplierAddressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier(WidgetRef ref) async {
    if (supplierNameController.text.trim().isEmpty) {
      EasyLoading.showError('El nombre del proveedor es requerido');
      return;
    }

    setState(() => isLoading = true);
    EasyLoading.show(status: 'Guardando proveedor...');

    try {
      final openingBalance = previousDueController.text.isEmpty ? '0' : previousDueController.text;

      final customerModel = CustomerModel(
        customerName: supplierNameController.text.trim(),
        phoneNumber: supplierPhoneController.text.trim(),
        type: 'Supplier',
        profilePicture: '',
        emailAddress: supplierEmailController.text.trim(),
        customerAddress: supplierAddressController.text.trim(),
        dueAmount: openingBalance,
        openingBalance: openingBalance,
        remainedBalance: openingBalance,
        gst: '',
        receiveWhatsappUpdates: false,
      );

      final apiService = ApiService();
      final response = await apiService.post('customers', Map<String, dynamic>.from(customerModel.toJson()));

      if (response.success && response.data != null) {
        EasyLoading.showSuccess('Proveedor creado exitosamente');

        // Refrescar la lista de proveedores
        ref.invalidate(supplierProvider);
        ref.invalidate(allCustomerProvider);

        // Cerrar el popup y retornar el proveedor creado
        if (mounted) {
          final newSupplier = CustomerModel.fromJson(response.data['customer'] ?? response.data);
          Navigator.pop(context, newSupplier);
        }
      } else {
        EasyLoading.showError(response.error ?? 'Error al crear proveedor');
      }
    } catch (e) {
      print('[PurchaseCreateCustomerPopUp] Error: $e');
      EasyLoading.showError('Error al crear proveedor');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return SizedBox(
          width: 900,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Text(
                      'Agregar Proveedor',
                      style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    const Spacer(),
                    const Icon(FeatherIcons.x, color: kTitleColor).onTap(() => Navigator.pop(context))
                  ],
                ),
              ),
              const Divider(
                thickness: 1.0,
                color: kLitGreyColor,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: supplierNameController,
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.NAME,
                            decoration: kInputDecoration.copyWith(
                              labelText: 'Nombre del Proveedor *',
                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              hintText: 'Ingrese el nombre',
                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        Expanded(
                          child: AppTextField(
                            controller: previousDueController,
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.PHONE,
                            decoration: kInputDecoration.copyWith(
                              labelText: 'Balance Inicial',
                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              hintText: '\$0.00',
                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: supplierPhoneController,
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.PHONE,
                            decoration: kInputDecoration.copyWith(
                              labelText: 'Teléfono',
                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              hintText: 'Ingrese el teléfono',
                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        Expanded(
                          child: FormField(
                            builder: (FormFieldState<dynamic> field) {
                              return InputDecorator(
                                decoration: const InputDecoration(
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                      borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.all(6.0),
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    labelText: 'Tipo'),
                                child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedSupplierType = value!;
                                    });
                                  },
                                  value: selectedSupplierType,
                                  items: supplierType.map((String items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(items),
                                    );
                                  }).toList(),
                                )),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: supplierEmailController,
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.EMAIL,
                            decoration: kInputDecoration.copyWith(
                              labelText: 'Email',
                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              hintText: 'Ingrese el email',
                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20.0),
                        Expanded(
                          child: AppTextField(
                            controller: supplierAddressController,
                            showCursor: true,
                            cursorColor: kTitleColor,
                            textFieldType: TextFieldType.NAME,
                            decoration: kInputDecoration.copyWith(
                              labelText: 'Dirección',
                              labelStyle: kTextStyle.copyWith(color: kTitleColor),
                              hintText: 'Ingrese la dirección',
                              hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    AppTextField(
                      controller: noteController,
                      showCursor: true,
                      cursorColor: kTitleColor,
                      textFieldType: TextFieldType.NAME,
                      decoration: kInputDecoration.copyWith(
                        labelText: 'Nota',
                        labelStyle: kTextStyle.copyWith(color: kTitleColor),
                        hintText: 'Ingrese una nota (opcional)',
                        hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRedTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: kTextStyle.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBlueTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                            onPressed: isLoading ? null : () => _saveSupplier(ref),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Guardar',
                                    style: kTextStyle.copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
