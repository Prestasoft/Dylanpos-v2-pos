import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:typed_data';
import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/general_setting_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../PDF/print_pdf.dart';
import '../../Provider/customer_provider.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../Provider/due_transaction_provider.dart';
import '../../Provider/profile_provider.dart';
import '../../Provider/transactions_provider.dart';
import '../../const.dart';
import '../../model/customer_model.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/due_transaction_model.dart';
import '../../subscription.dart';
import '../Widgets/Constant Data/constant.dart';
import '../currency/currency_provider.dart';
import '../../Provider/bank_provider.dart';
import '../../services/whatsapp_template_service.dart';
import '../../services/whatsapp_credentials_service.dart';
import '../../model/transfer_verification_model.dart';
import '../../Provider/transfer_verification_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ShowDuePaymentPopUp extends StatefulWidget {
  const ShowDuePaymentPopUp({super.key, required this.customerModel});
  final CustomerModel customerModel;

  @override
  State<ShowDuePaymentPopUp> createState() => _ShowDuePaymentPopUpState();
}

class _ShowDuePaymentPopUpState extends State<ShowDuePaymentPopUp> {
  // List of items in our dropdown menu
  List<String> items = ['Seleccionar Factura'];
  int count = 0;

  bool saleButtonClicked = false;

  late DueTransactionModel dueTransactionModel = DueTransactionModel(
    customerName: widget.customerModel.customerName,
    customerPhone: widget.customerModel.phoneNumber,
    customerAddress: widget.customerModel.customerAddress,
    customerType: widget.customerModel.type,
    invoiceNumber: invoice.toString(),
    purchaseDate: DateTime.now().toString(),
    customerGst: widget.customerModel.gst,
    sendWhatsappMessage: widget.customerModel.receiveWhatsappUpdates,
  );

  List<String> paymentItem = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
  ];
  String selectedPaymentOption = 'Efectivo';
  String? selectedBankId;
  String? selectedBankName;

  // Campos para verificación de transferencia
  final TextEditingController transferHolderNameController = TextEditingController();
  final TextEditingController transferReferenceController = TextEditingController();
  String? transferReceiptUrl;
  bool isUploadingReceipt = false;

  /// Método para seleccionar y subir comprobante de transferencia
  void _pickTransferReceipt() {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];

          // Verificar formato (solo formatos web compatibles)
          final fileName = file.name.toLowerCase();
          final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
          final isValidFormat = allowedExtensions.any((ext) => fileName.endsWith(ext));

          if (!isValidFormat) {
            EasyLoading.showError('Formato no soportado. Use JPG, PNG, GIF o WebP.');
            return;
          }

          // Verificar tamaño (max 5MB)
          if (file.size > 5 * 1024 * 1024) {
            EasyLoading.showError('La imagen no debe superar 5MB');
            return;
          }

          setState(() => isUploadingReceipt = true);
          EasyLoading.show(status: 'Subiendo comprobante...');

          try {
            final reader = html.FileReader();
            reader.readAsDataUrl(file);

            await reader.onLoad.first;
            final base64Data = reader.result as String;

            // Subir al servidor API
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final safeFileName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
            final filename = 'receipt_${timestamp}_$safeFileName';

            final apiService = ApiService();
            final response = await apiService.post('uploads/transfer-receipt', {
              'base64Data': base64Data.split(',').last,
              'filename': filename,
              'contentType': file.type,
            });

            if (response.success && response.data != null) {
              final downloadUrl = response.data['url'] as String;
              setState(() {
                transferReceiptUrl = downloadUrl;
                isUploadingReceipt = false;
              });
              EasyLoading.showSuccess('Comprobante cargado');
            } else {
              throw Exception(response.message ?? 'Error al subir imagen');
            }
          } catch (e) {
            setState(() => isUploadingReceipt = false);
            EasyLoading.showError('Error al subir imagen: $e');
          }
        }
      });
    } catch (e) {
      EasyLoading.showError('Error al seleccionar imagen');
    }
  }

  DropdownButton<String> getOption() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentItem) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.normal),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPaymentOption,
      onChanged: (value) {
        setState(() {
          selectedPaymentOption = value!;
        });
      },
    );
  }

  double dueAmount = 0.0;
  double returnAmount = 0.0;
  String selectedInvoice = 'Seleccionar Factura';
  String dropdownValue = 'Seleccionar Factura';
  int invoice = 0;

  TextEditingController payingAmountController = TextEditingController();
  TextEditingController changeAmountController = TextEditingController();
  TextEditingController dueAmountController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    dueAmount = widget.customerModel.remainedBalance.toDouble();
  }

  Future<void> _sendPdfViaWhatsApp({
    required String phoneNumber,
    required Uint8List pdfData,
    required String invoiceNumber,
    required String customerName,
  }) async {
    try {
      // Validar número de teléfono
      // final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      // if (!cleanedPhone.startsWith('+')) {
      //   throw Exception('El número debe incluir código de país (ej: +1...)');
      // }

      EasyLoading.show(status: 'Preparando envío...');

      // Codificar PDF en Base64
      final pdfBase64 = base64Encode(pdfData);

      // Crear mensaje usando plantilla de WhatsApp
      final template = await WhatsAppTemplateService.getTemplate('payment_receipt');
      final safeMessage = WhatsAppTemplateService.replaceVariables(template, {
        'nombre': customerName,
        'factura': invoiceNumber,
      });

      // Obtener credenciales dinámicas de WhatsApp
      final credentials = await WhatsAppCredentialsService.getCredentials();

     // Crear cuerpo de la petición
      final body = {
        'token': credentials.token,
        'to': phoneNumber,
        'filename': 'Comprobante_${invoiceNumber}.pdf',
        'document': pdfBase64,
        'caption': safeMessage,
      };

      // Configurar la petición HTTP
      final url = Uri.parse(credentials.getApiUrl('messages/document'));
      final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
      
      EasyLoading.show(status: 'Enviando...');
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('Enviado exitosamente');
      } else {
        throw Exception('Error en API: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      EasyLoading.showError('Error al enviar: ${e.toString().replaceAll('\n', ' ')}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);

    count++;
    return Consumer(
      builder: (context, consumerRef, __) {
        final customerProviderRef = widget.customerModel.type == 'Supplier' ? consumerRef.watch(purchaseTransitionProvider) : consumerRef.watch(transitionProvider);
        final personalData = consumerRef.watch(profileDetailsProvider);
        final settingProvider = consumerRef.watch(generalSettingProvider);

        return personalData.when(data: (data) {
          invoice = data.dueInvoiceCounter;

          return SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///_________title_and_close_button__________________________________________________
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          lang.S.of(context).createPayment,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          GoRouter.of(context).pop();
                        },
                        icon: const Icon(
                          FeatherIcons.x,
                          color: kNeutral500,
                          size: 20.0,
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(
                  thickness: 1.0,
                  height: 1,
                  color: kNeutral300,
                ),

                ///____________________________________________________________________________________
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: ResponsiveGridRow(children: [
                            ResponsiveGridCol(
                              xs: 12,
                              md: 9,
                              lg: 9,
                              child: customerProviderRef.when(data: (customer) {
                                for (var element in customer) {
                                  if (element.customerPhone == widget.customerModel.phoneNumber && element.dueAmount != 0 && count < 2) {
                                    items.add(element.invoiceNumber);
                                  }
                                  if (selectedInvoice == element.invoiceNumber) {
                                    dueAmount = element.dueAmount!.toDouble();
                                  } else if (selectedInvoice == 'Seleccionar Factura') {
                                    dueAmount = widget.customerModel.remainedBalance.toDouble();
                                  }
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(05),
                                      ),
                                      border: Border.all(width: 1, color: kNeutral400),
                                    ),
                                    child: Center(
                                      child: Theme(
                                        data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton(
                                            value: dropdownValue,
                                            icon: const Icon(Icons.keyboard_arrow_down),
                                            items: items.map((String items) {
                                              return DropdownMenuItem(
                                                value: items,
                                                child: Text(items,
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: kNeutral500,
                                                    )),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                payingAmountController.text = '0';
                                                payingAmountController.clear();
                                                dropdownValue = newValue.toString();
                                                selectedInvoice = newValue.toString();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }, error: (e, stack) {
                                return Text(e.toString());
                              }, loading: () {
                                return const Center(child: CircularProgressIndicator());
                              }),
                            ),
                            ResponsiveGridCol(xs: 0, md: 3, lg: 3, child: const SizedBox.shrink())
                          ])),
                      // ResponsiveGridCol(
                      //   xs: 12,
                      //   md: 6,
                      //   lg: 6,
                      //   child: customerProviderRef.when(data: (customer) {
                      //     for (var element in customer) {
                      //       if (element.customerPhone == widget.customerModel.phoneNumber && element.dueAmount != 0 && count < 2) {
                      //         items.add(element.invoiceNumber);
                      //       }
                      //       if (selectedInvoice == element.invoiceNumber) {
                      //         dueAmount = element.dueAmount!.toDouble();
                      //       } else if (selectedInvoice == 'Select Invoice') {
                      //         dueAmount = widget.customerModel.remainedBalance.toDouble();
                      //       }
                      //     }
                      //     return Padding(
                      //       padding: const EdgeInsets.all(12.0),
                      //       child: Container(
                      //         height: 48,
                      //         decoration: BoxDecoration(
                      //           borderRadius: const BorderRadius.all(
                      //             Radius.circular(05),
                      //           ),
                      //           border: Border.all(width: 1, color: kNeutral400),
                      //         ),
                      //         child: Center(
                      //           child: Theme(
                      //             data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                      //             child: DropdownButtonHideUnderline(
                      //               child: DropdownButton(
                      //                 value: dropdownValue,
                      //                 icon: const Icon(Icons.keyboard_arrow_down),
                      //                 items: items.map((String items) {
                      //                   return DropdownMenuItem(
                      //                     value: items,
                      //                     child: Text(items,
                      //                         style: theme.textTheme.titleMedium?.copyWith(
                      //                           fontWeight: FontWeight.w600,
                      //                           color: kNeutral500,
                      //                         )),
                      //                   );
                      //                 }).toList(),
                      //                 onChanged: (newValue) {
                      //                   setState(() {
                      //                     payingAmountController.text = '0';
                      //                     payingAmountController.clear();
                      //                     dropdownValue = newValue.toString();
                      //                     selectedInvoice = newValue.toString();
                      //                   });
                      //                 },
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   }, error: (e, stack) {
                      //     return Text(e.toString());
                      //   }, loading: () {
                      //     return const Center(child: CircularProgressIndicator());
                      //   }),
                      // ),
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              color: kbgColor,
                              border: Border.all(color: kbgColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang.S.of(context).grandTotal,
                                  style: theme.textTheme.titleMedium,
                                ),
                                // const Spacer(),
                                Text(
                                  '$globalCurrency ${myFormat.format(double.tryParse(dueAmount.toString()) ?? 0)}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              lang.S.of(context).payingAmount,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: TextFormField(
                              controller: payingAmountController,
                              onChanged: (value) {
                                setState(() {
                                  double paidAmount = double.parse(value);
                                  if (paidAmount > dueAmount) {
                                    changeAmountController.text = (paidAmount - dueAmount).toString();
                                    dueAmountController.text = '0';
                                  } else {
                                    dueAmountController.text = (dueAmount - paidAmount).abs().toString();
                                    changeAmountController.text = '0';
                                  }
                                });
                              },
                              showCursor: true,
                              cursorColor: kTitleColor,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: lang.S.of(context).enterPaidAmount,
                              ),
                            ),
                          )),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              lang.S.of(context).changeAmount,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: changeAmountController,
                              cursorColor: kTitleColor,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: lang.S.of(context).changeAmount,
                              ),
                            ),
                          )),
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            lang.S.of(context).dueAmount,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              readOnly: true,
                              controller: dueAmountController,
                              cursorColor: kTitleColor,
                              keyboardType: TextInputType.name,
                              decoration: InputDecoration(
                                hintText: lang.S.of(context).dueAmount,
                              ),
                            ),
                          ))
                    ]),
                    ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              lang.S.of(context).paymentType,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 48,
                              child: FormField(
                                builder: (FormFieldState<dynamic> field) {
                                  return InputDecorator(
                                    decoration: const InputDecoration(),
                                    child: Theme(
                                      data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                      child: DropdownButtonHideUnderline(
                                        child: getOption(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ))
                    ]),
                    // Bank selection when transfer is selected
                    if (selectedPaymentOption == 'Transferencia')
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Banco',
                                style: theme.textTheme.bodyLarge,
                              ),
                            )),
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Consumer(
                                builder: (context, ref, _) {
                                  final banksAsync = ref.watch(allBanksProvider);
                                  return banksAsync.when(
                                    data: (banks) {
                                      return SizedBox(
                                        height: 48,
                                        child: FormField(
                                          builder: (FormFieldState<dynamic> field) {
                                            return InputDecorator(
                                              decoration: const InputDecoration(),
                                              child: Theme(
                                                data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: selectedBankId,
                                                    hint: Text('Seleccionar banco'),
                                                    items: banks.map((bank) {
                                                      return DropdownMenuItem<String>(
                                                        value: bank.bankId,
                                                        child: Text(
                                                          bank.bankName ?? '',
                                                          style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.normal),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (newValue) {
                                                      setState(() {
                                                        selectedBankId = newValue;
                                                        selectedBankName = banks.firstWhere((bank) => bank.bankId == newValue).bankName;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    loading: () => SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                                    error: (error, stack) => SizedBox(height: 48, child: Center(child: Text('Error cargando bancos'))),
                                  );
                                },
                              ),
                            ))
                      ]),
                    // Campos adicionales para transferencia
                    if (selectedPaymentOption == 'Transferencia')
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Nombre del Titular *',
                                style: theme.textTheme.bodyLarge,
                              ),
                            )),
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                controller: transferHolderNameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nombre de quien transfiere',
                                ),
                              ),
                            ))
                      ]),
                    if (selectedPaymentOption == 'Transferencia')
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'No. Referencia',
                                style: theme.textTheme.bodyLarge,
                              ),
                            )),
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: TextFormField(
                                controller: transferReferenceController,
                                decoration: const InputDecoration(
                                  hintText: 'Número de referencia (opcional)',
                                ),
                              ),
                            ))
                      ]),
                    if (selectedPaymentOption == 'Transferencia')
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Comprobante *',
                                style: theme.textTheme.bodyLarge,
                              ),
                            )),
                        ResponsiveGridCol(
                            xs: 12,
                            md: 6,
                            lg: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (transferReceiptUrl != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Comprobante cargado'),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () => setState(() => transferReceiptUrl = null),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _pickTransferReceipt();
                                      },
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Subir Comprobante'),
                                    ),
                                ],
                              ),
                            ))
                      ]),
                    const SizedBox(height: 20.0),
                    ResponsiveGridRow(children: [
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => GoRouter.of(context).pop(),
                                child: Text(
                                  lang.S.of(context).cancel,
                                )),
                          )),
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: settingProvider.when(data: (setting) {
                              return ElevatedButton(
                                onPressed: saleButtonClicked
                                    ? () {}
                                    : () async {
                                        // Validaciones para transferencia
                                        if (selectedPaymentOption == 'Transferencia') {
                                          if (selectedBankId == null) {
                                            EasyLoading.showError('Seleccione un banco para la transferencia');
                                            return;
                                          }
                                          if (transferHolderNameController.text.trim().isEmpty) {
                                            EasyLoading.showError('Ingrese el nombre del titular');
                                            return;
                                          }
                                          if (transferReceiptUrl == null) {
                                            EasyLoading.showError('Suba el comprobante de la transferencia');
                                            return;
                                          }
                                        }

                                        if (dueAmount > 0 && !payingAmountController.text.isEmptyOrNull && payingAmountController.text.toInt() > 0) {
                                          try {
                                            setState(() => saleButtonClicked = true);
                                            // EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);

                                            // 1. Guardar la transacción en PostgreSQL
                                            final apiService = ApiService();

                                            dueTransactionModel.invoiceNumber = selectedInvoice;
                                            dueTransactionModel.totalDue = dueAmount;
                                            dueTransactionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                                            dueAmountController.text.toDouble() <= 0 ? dueTransactionModel.isPaid = true : dueTransactionModel.isPaid = false;
                                            dueAmountController.text.toDouble() <= 0
                                                ? {dueTransactionModel.dueAmountAfterPay = 0, dueTransactionModel.payDueAmount = dueAmount}
                                                : {dueTransactionModel.dueAmountAfterPay = dueAmountController.text.toDouble(), dueTransactionModel.payDueAmount = dueAmount - dueAmountController.text.toDouble()};

                                            dueTransactionModel.paymentType = selectedPaymentOption;
                                            dueTransactionModel.sendWhatsappMessage = widget.customerModel.receiveWhatsappUpdates;

                                            // Agregar información del banco si es transferencia
                                            if (selectedPaymentOption == 'Transferencia' && selectedBankId != null) {
                                              dueTransactionModel.bankId = selectedBankId;
                                              dueTransactionModel.bankName = selectedBankName;
                                            }

                                            await apiService.post('due-transactions', Map<String, dynamic>.from(dueTransactionModel.toJson()));

                                            // Crear registro de verificación de transferencia si aplica
                                            if (selectedPaymentOption == 'Transferencia' && transferReceiptUrl != null) {
                                              try {
                                                final transferVerification = TransferVerificationModel(
                                                  branchId: apiService.branchId ?? 'sdo',
                                                  invoiceNumber: selectedInvoice,
                                                  customerName: dueTransactionModel.customerName ?? '',
                                                  customerPhone: dueTransactionModel.customerPhone ?? '',
                                                  bankName: selectedBankName ?? '',
                                                  holderName: transferHolderNameController.text.trim(),
                                                  referenceNumber: transferReferenceController.text.trim().isNotEmpty
                                                      ? transferReferenceController.text.trim()
                                                      : null,
                                                  transferDate: DateTime.now().toIso8601String(),
                                                  amount: dueTransactionModel.payDueAmount ?? 0.0,
                                                  receiptUrl: transferReceiptUrl!,
                                                  status: 'pending',
                                                  sellerName: isSubUser ? constSubUserTitle : 'Admin',
                                                  createdAt: DateTime.now().toIso8601String(),
                                                );

                                                await transferVerificationRepository.createTransfer(transferVerification);
                                                print('DEBUG: Registro de verificación de transferencia creado (DuePopup)');
                                              } catch (e) {
                                                print('ERROR al crear verificación de transferencia: $e');
                                                // No bloquear el pago si falla la creación del registro
                                              }
                                            }

                                            // 2. Preguntar si desea enviar por WhatsApp
                                            final sendWhatsApp = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Enviar comprobante'),
                                                content: Text('¿Desea enviar el comprobante de pago por WhatsApp al cliente?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: Text('Sí, enviar'),
                                                  ),
                                                ],
                                              ),
                                            ) ?? false;

                                            if (sendWhatsApp) {
                                              try {
                                                EasyLoading.show(status: 'Generando comprobante...');
                                                
                                                // Generar PDF para WhatsApp
                                                final pdfData = await GeneratePdfAndPrint().printDueInvoice(
                                                  personalInformationModel: data,
                                                  dueTransactionModel: dueTransactionModel,
                                                  setting: setting,
                                                  returnPdfData: true,
                                                  skipWhatsappCheck: true, // Evitar doble envío de WhatsApp
                                                );

                                                if (pdfData != null) {
                                                  await _sendPdfViaWhatsApp(
                                                    phoneNumber: dueTransactionModel.customerPhone ?? widget.customerModel.phoneNumber,
                                                    pdfData: pdfData,
                                                    invoiceNumber: selectedInvoice,
                                                    customerName: dueTransactionModel.customerName ?? widget.customerModel.customerName,
                                                  );
                                                }
                                              } catch (e) {
                                                EasyLoading.showError('Error al enviar: ${e.toString()}');
                                              }
                                            }

                                            // 3. Siempre imprimir el PDF (independientemente de si se envió por WhatsApp)
                                            try {
                                              await GeneratePdfAndPrint().printDueInvoice(
                                                personalInformationModel: data,
                                                dueTransactionModel: dueTransactionModel,
                                                setting: setting,
                                              );
                                            } catch (e) {
                                              EasyLoading.showError('Error al imprimir: ${e.toString()}');
                                            }

                                            // Resto del código para actualizar datos...
                                            selectedInvoice != 'Select Invoice'
                                                ? updateDueInvoice(
                                                    type: widget.customerModel.type,
                                                    invoice: selectedInvoice.toString(),
                                                    remainDueAmount: dueAmountController.text.toInt(),
                                                  )
                                                : null;

                                            // Actualización de transacción diaria
                                            if (dueTransactionModel.customerType == 'Supplier') {
                                              DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                name: dueTransactionModel.customerName,
                                                date: dueTransactionModel.purchaseDate,
                                                type: 'Due Payment',
                                                total: dueTransactionModel.totalDue!.toDouble(),
                                                paymentIn: 0,
                                                paymentOut: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                id: selectedInvoice,
                                                // Campos directos para mostrar en el reporte
                                                paymentType: dueTransactionModel.paymentType,
                                                sellerName: dueTransactionModel.sellerName,
                                                invoiceNumber: selectedInvoice,
                                                dueTransactionModel: dueTransactionModel,
                                              );
                                              postDailyTransaction(dailyTransactionModel: dailyTransaction);
                                            } else {
                                              DailyTransactionModel dailyTransaction = DailyTransactionModel(
                                                name: dueTransactionModel.customerName,
                                                date: dueTransactionModel.purchaseDate,
                                                type: 'Due Collection',
                                                total: dueTransactionModel.totalDue!.toDouble(),
                                                paymentIn: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                paymentOut: 0,
                                                remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                                                id: selectedInvoice,
                                                // Campos directos para mostrar en el reporte
                                                paymentType: dueTransactionModel.paymentType,
                                                sellerName: dueTransactionModel.sellerName,
                                                invoiceNumber: selectedInvoice,
                                                dueTransactionModel: dueTransactionModel,
                                              );
                                              postDailyTransaction(dailyTransactionModel: dailyTransaction);
                                            }

                                            // Actualizar saldo del cliente via API
                                            String? customerId;
                                            int previousDue = 0;
                                            int remainedBalance = 0;

                                            // Buscar cliente por teléfono
                                            final customerResponse = await apiService.get('customers', queryParams: {
                                              'phoneNumber': widget.customerModel.phoneNumber,
                                              'limit': '1',
                                            });

                                            if (customerResponse.success && customerResponse.data != null) {
                                              final customers = customerResponse.data['customers'] as List<dynamic>? ?? [];
                                              if (customers.isNotEmpty) {
                                                final customerData = Map<String, dynamic>.from(customers.first);
                                                customerId = customerData['id']?.toString();
                                                previousDue = int.tryParse(customerData['due']?.toString() ?? '0') ?? 0;
                                                remainedBalance = int.tryParse(customerData['remainedBalance']?.toString() ?? '0') ?? 0;
                                              }
                                            }

                                            int totalDue = previousDue - dueTransactionModel.payDueAmount!.toInt();
                                            int remainedDue = remainedBalance - dueTransactionModel.payDueAmount!.toInt();

                                            if (customerId != null) {
                                              await apiService.put('customers/$customerId', {'due': '$totalDue'});
                                              if (selectedInvoice == 'Select Invoice') {
                                                await apiService.put('customers/$customerId', {'remainedBalance': '$remainedDue'});
                                              }
                                            }

                                            // Actualizar contadores y providers
                                            updateInvoice(typeOfInvoice: 'dueInvoiceCounter', invoice: data.dueInvoiceCounter.toInt());
                                            Subscription.decreaseSubscriptionLimits(itemType: 'dueNumber', context: context);

                                            consumerRef.refresh(allCustomerProvider);
                                            consumerRef.refresh(transitionProvider);
                                            consumerRef.refresh(purchaseTransitionProvider);
                                            consumerRef.refresh(dueTransactionProvider);
                                            consumerRef.refresh(profileDetailsProvider);
                                            consumerRef.refresh(dailyTransactionProvider);

                                            finish(context);
                                            EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                                          } catch (e) {
                                            setState(() => saleButtonClicked = false);
                                            EasyLoading.showError('Error: ${e.toString()}');
                                          } finally {
                                            setState(() => saleButtonClicked = false);
                                          }
                                        } else if (dueAmount <= 0) {
                                          EasyLoading.showError(lang.S.of(context).selectAInvoice);
                                        } else if (payingAmountController.text.isEmptyOrNull || payingAmountController.text.toInt() <= 0) {
                                          EasyLoading.showError(lang.S.of(context).pleaseEnterAmount);
                                        }
                                      },
                                child: Text(
                                  lang.S.of(context).submit,
                                  style: kTextStyle.copyWith(color: kWhite),
                                ),
                              );
                            }, error: (e, stack) {
                              return Text(e.toString());
                            }, loading: () {
                              return CircularProgressIndicator();
                            }),
                          ))
                    ]),
                    // Row(
                    //   mainAxisSize: MainAxisSize.max,
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Container(
                    //         padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(5.0),
                    //           color: kRedTextColor,
                    //         ),
                    //         child: Text(
                    //           lang.S.of(context).cancel,
                    //           style: kTextStyle.copyWith(color: kWhite),
                    //         )).onTap(() => {
                    //           finish(context),
                    //         }),
                    //     const SizedBox(width: 40.0),
                    //     Container(
                    //       padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 10.0, bottom: 10.0),
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(5.0),
                    //         color: kBlueTextColor,
                    //       ),
                    //       child: Text(
                    //         lang.S.of(context).submit,
                    //         style: kTextStyle.copyWith(color: kWhite),
                    //       ),
                    //     ).onTap(
                    //       saleButtonClicked
                    //           ? () {}
                    //           : () async {
                    //               if (dueAmount > 0 && !payingAmountController.text.isEmptyOrNull && payingAmountController.text.toInt() > 0) {
                    //                 try {
                    //                   setState(() {
                    //                     saleButtonClicked = true;
                    //                   });
                    //                   EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                    //                   DatabaseReference ref = FirebaseDatabase.instance.ref("${await getUserID()}/Due Transaction");
                    //
                    //                   dueTransactionModel.totalDue = dueAmount;
                    //                   dueTransactionModel.sellerName = isSubUser ? constSubUserTitle : 'Admin';
                    //                   dueAmountController.text.toDouble() <= 0 ? dueTransactionModel.isPaid = true : dueTransactionModel.isPaid = false;
                    //                   dueAmountController.text.toDouble() <= 0
                    //                       ? {dueTransactionModel.dueAmountAfterPay = 0, dueTransactionModel.payDueAmount = dueAmount}
                    //                       : {
                    //                           dueTransactionModel.dueAmountAfterPay = dueAmountController.text.toDouble(),
                    //                           dueTransactionModel.payDueAmount = dueAmount - dueAmountController.text.toDouble()
                    //                         };
                    //
                    //                   dueTransactionModel.paymentType = selectedPaymentOption;
                    //                   dueTransactionModel.sendWhatsappMessage = widget.customerModel.receiveWhatsappUpdates;
                    //                   await ref.push().set(dueTransactionModel.toJson());
                    //
                    //                   await GeneratePdfAndPrint().printDueInvoice(personalInformationModel: data, dueTransactionModel: dueTransactionModel);
                    //
                    //                   ///_____UpdateInvoice__________________________________________________
                    //                   selectedInvoice != 'Select Invoice'
                    //                       ? updateDueInvoice(
                    //                           type: widget.customerModel.type,
                    //                           invoice: selectedInvoice.toString(),
                    //                           remainDueAmount: dueAmountController.text.toInt(),
                    //                         )
                    //                       : null;
                    //
                    //                   ///________daily_transactionModel_________________________________________________________________________
                    //
                    //                   if (dueTransactionModel.customerType == 'Supplier') {
                    //                     DailyTransactionModel dailyTransaction = DailyTransactionModel(
                    //                       name: dueTransactionModel.customerName,
                    //                       date: dueTransactionModel.purchaseDate,
                    //                       type: 'Due Payment',
                    //                       total: dueTransactionModel.totalDue!.toDouble(),
                    //                       paymentIn: 0,
                    //                       paymentOut: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       id: dueTransactionModel.invoiceNumber,
                    //                       dueTransactionModel: dueTransactionModel,
                    //                     );
                    //                     postDailyTransaction(dailyTransactionModel: dailyTransaction);
                    //                   } else {
                    //                     DailyTransactionModel dailyTransaction = DailyTransactionModel(
                    //                       name: dueTransactionModel.customerName,
                    //                       date: dueTransactionModel.purchaseDate,
                    //                       type: 'Due Collection',
                    //                       total: dueTransactionModel.totalDue!.toDouble(),
                    //                       paymentIn: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       paymentOut: 0,
                    //                       remainingBalance: dueTransactionModel.totalDue!.toDouble() - dueTransactionModel.dueAmountAfterPay!.toDouble(),
                    //                       id: dueTransactionModel.invoiceNumber,
                    //                       dueTransactionModel: dueTransactionModel,
                    //                     );
                    //                     postDailyTransaction(dailyTransactionModel: dailyTransaction);
                    //                   }
                    //
                    //                   ///_________DueUpdate______________________________________________________
                    //                   final cRef = FirebaseDatabase.instance.ref('${await getUserID()}/Customers/');
                    //                   String? key;
                    //
                    //                   await FirebaseDatabase.instance.ref(await getUserID()).child('Customers').orderByKey().get().then((value) {
                    //                     for (var element in value.children) {
                    //                       var data = jsonDecode(jsonEncode(element.value));
                    //                       if (data['phoneNumber'] == widget.customerModel.phoneNumber) {
                    //                         key = element.key;
                    //                       }
                    //                     }
                    //                   });
                    //                   var data1 = await cRef.child('$key/due').get();
                    //                   var data2 = await cRef.child('$key/remainedBalance').get();
                    //                   int previousDue = data1.value.toString().toInt();
                    //                   int remainedBalance = data2.value.toString().toInt();
                    //
                    //                   int totalDue = previousDue - dueTransactionModel.payDueAmount!.toInt();
                    //                   int remainedDue = remainedBalance - dueTransactionModel.payDueAmount!.toInt();
                    //                   cRef.child(key!).update({'due': '$totalDue'});
                    //                   selectedInvoice == 'Select Invoice' ? cRef.child(key!).update({'remainedBalance': '$remainedDue'}) : null;
                    //
                    //                   ///_________Invoice Increase____________________________________________________________________________
                    //                   updateInvoice(
                    //                     typeOfInvoice: 'dueInvoiceCounter',
                    //                     invoice: data.dueInvoiceCounter.toInt(),
                    //                   );
                    //
                    //                   ///________Subscription_____________________________________________________
                    //                   Subscription.decreaseSubscriptionLimits(itemType: 'dueNumber', context: context);
                    //
                    //                   consumerRef.refresh(allCustomerProvider);
                    //                   consumerRef.refresh(transitionProvider);
                    //                   consumerRef.refresh(purchaseTransitionProvider);
                    //                   consumerRef.refresh(dueTransactionProvider);
                    //                   consumerRef.refresh(profileDetailsProvider);
                    //                   consumerRef.refresh(dailyTransactionProvider);
                    //
                    //                   finish(context);
                    //                   EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully);
                    //                 } catch (e) {
                    //                   setState(() {
                    //                     saleButtonClicked = false;
                    //                   });
                    //                   EasyLoading.dismiss();
                    //                   //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    //                 }
                    //               } else if (dueAmount <= 0) {
                    //                 // EasyLoading.showError('Select a Invoice');
                    //                 EasyLoading.showError(lang.S.of(context).selectAInvoice);
                    //               } else if (payingAmountController.text.isEmptyOrNull || payingAmountController.text.toInt() <= 0) {
                    //                 //EasyLoading.showError('Please Enter Amount');
                    //                 EasyLoading.showError(lang.S.of(context).pleaseEnterAmount);
                    //               }
                    //             },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ],
            ),
          );
        }, error: (e, stack) {
          return Center(
            child: Text(e.toString()),
          );
        }, loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
      },
    );
  }

  void updateDueInvoice({required String type, required String invoice, required int remainDueAmount}) async {
    final apiService = ApiService();
    final endpoint = type == 'Supplier' ? 'purchases' : 'sales';
    String? transactionId;

    // Buscar la transacción por número de factura
    final response = await apiService.get(endpoint, queryParams: {
      'invoiceNumber': invoice,
      'limit': '1',
    });

    if (response.success && response.data != null) {
      final transactions = response.data[endpoint] as List<dynamic>? ?? [];
      if (transactions.isNotEmpty) {
        final transactionData = Map<String, dynamic>.from(transactions.first);
        transactionId = transactionData['id']?.toString();
      }
    }

    if (transactionId != null) {
      await apiService.put('$endpoint/$transactionId', {
        'dueAmount': '$remainDueAmount',
      });
    }
  }
}
