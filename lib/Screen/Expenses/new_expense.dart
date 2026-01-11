// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/all_expanse_provider.dart';
import 'package:salespro_admin/Provider/expense_category_proivder.dart';
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/expense_model.dart';
import 'package:salespro_admin/model/customer_model.dart';

import '../../Provider/daily_transaction_provider.dart';
import '../../commas.dart';
import '../../const.dart';
import '../../model/daily_transaction_model.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';

class NewExpense extends StatefulWidget {
  const NewExpense({super.key});

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  bool saleButtonClicked = false;

  void showCategoryPopUp() {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SizedBox(
                width: 600,
                height: context.height() / 2.5,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration:
                                const BoxDecoration(shape: BoxShape.rectangle),
                            child: const Icon(
                              FeatherIcons.plus,
                              color: kTitleColor,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            lang.S.of(context).addCategory,
                            style: kTextStyle.copyWith(
                                color: kTitleColor,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(
                            FeatherIcons.x,
                            color: kTitleColor,
                            size: 50.0,
                          ).onTap(() {
                            finish(context);
                          })
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Text(
                            lang.S.of(context).nam,
                            style: kTextStyle.copyWith(
                                color: kTitleColor, fontSize: 18.0),
                          ),
                          const SizedBox(width: 50),
                          SizedBox(
                            width: 400,
                            child: Expanded(
                              child: AppTextField(
                                showCursor: true,
                                cursorColor: kTitleColor,
                                textFieldType: TextFieldType.NAME,
                                decoration: kInputDecoration.copyWith(
                                  hintText: lang.S.of(context).name,
                                  hintStyle: kTextStyle.copyWith(
                                      color: kGreyTextColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Divider(
                        thickness: 1.0,
                        color: kGreyTextColor.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kRedTextColor),
                            child: Text(
                              lang.S.of(context).cancel,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            finish(context);
                          }),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                color: kGreenTextColor),
                            child: Text(
                              lang.S.of(context).submit,
                              style: kTextStyle.copyWith(color: kWhite),
                            ),
                          ).onTap(() {
                            finish(context);
                          })
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<String> categories = [];

  List<String> get paymentMethods => [
        // 'Cash',
        lang.S.current.cash,
        //'Bank',
        lang.S.current.bank,
        //'Card',
        lang.S.current.card,
        //'Mobile Payment',
        lang.S.current.mobilePayment,
        //'Snacks',
        lang.S.current.snacks,
      ];

  String? selectedCategories;
  late String selectedPaymentType = paymentMethods.first;
  CustomerModel? selectedCustomer;
  bool showCustomerSelector = false;
  
  // Variables para el buscador de clientes
  TextEditingController customerSearchController = TextEditingController();
  List<CustomerModel> filteredCustomers = [];
  bool showCustomerDropdown = false;
  FocusNode customerSearchFocus = FocusNode();

  DropdownButton<String> getCategories() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in categories) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(Icons.keyboard_arrow_down),
      //hint: const Text('Select expense category'),
      hint: Text(lang.S.of(context).selectExpenseCategory),
      items: dropDownItems,
      value: selectedCategories,
      onChanged: (value) {
        setState(() {
          selectedCategories = value!;
          // Mostrar selector de cliente si la categoría es "Devolución Depósito"
          bool wasShowingCustomerSelector = showCustomerSelector;
          showCustomerSelector = selectedCategories?.toLowerCase().contains('devolución') == true || 
                                selectedCategories?.toLowerCase().contains('devolucion') == true ||
                                selectedCategories?.toLowerCase().contains('depósito') == true ||
                                selectedCategories?.toLowerCase().contains('deposito') == true ||
                                selectedCategories?.toLowerCase().contains('refund') == true ||
                                selectedCategories?.toLowerCase().contains('deposit') == true;
          
          // Si cambió de mostrar a no mostrar el selector, limpiar los campos relacionados
          if (wasShowingCustomerSelector && !showCustomerSelector) {
            selectedCustomer = null;
            customerSearchController.clear();
            expanseForNameController.clear();
            showCustomerDropdown = false;
          } else if (!wasShowingCustomerSelector && showCustomerSelector) {
            // Si ahora muestra el selector, limpiar el campo "Gasto para"
            expanseForNameController.clear();
          }
        });
      },
    );
  }

  DropdownButton<String> getPaymentMethods() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in paymentMethods) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      items: dropDownItems,
      value: selectedPaymentType,
      onChanged: (value) {
        setState(() {
          selectedPaymentType = value!;
        });
      },
    );
  }

  final ApiService _apiService = ApiService();

  Future<void> category() async {
    try {
      final response = await _apiService.get('categories/expenses');
      if (response.success && response.data != null) {
        final categoriesList = response.data['expense_categories'] as List<dynamic>? ??
            response.data['categories'] as List<dynamic>? ?? [];
        for (var element in categoriesList) {
          var data = ExpenseCategoryModel.fromJson(Map<String, dynamic>.from(element));
          categories.add(data.categoryName);
        }
      }
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
    setState(() {});
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool validateAndSave() {
    final form = formKey.currentState;
    if (form!.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    category();
    
    // Listener para el campo de búsqueda de clientes
    customerSearchFocus.addListener(() {
      if (!customerSearchFocus.hasFocus && customerSearchController.text.isEmpty) {
        setState(() {
          showCustomerDropdown = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    customerSearchController.dispose();
    customerSearchFocus.dispose();
    super.dispose();
  }
  
  // Método para filtrar clientes
  void filterCustomers(String query, List<CustomerModel> allCustomers) {
    setState(() {
      if (query.isEmpty) {
        filteredCustomers = allCustomers;
      } else {
        filteredCustomers = allCustomers.where((customer) {
          final nameLower = customer.customerName.toLowerCase();
          final phoneLower = customer.phoneNumber.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) || phoneLower.contains(queryLower);
        }).toList();
      }
      showCustomerDropdown = true;
    });
  }

  String expenseAmount = '0';
  TextEditingController expanseForNameController = TextEditingController();
  TextEditingController expanseAmountController = TextEditingController();
  TextEditingController expanseNoteController = TextEditingController();
  TextEditingController expanseRefController = TextEditingController();
  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(expenseCategoryProvider);

        return Scaffold(
          backgroundColor: kDarkWhite,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              // height: MediaQuery.of(context).size.height - 240,
              // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0), color: kWhite),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text.rich(TextSpan(
                                text: lang.S.of(context).expense,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        lang.S.of(context).addUpdateExpenseList,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(color: kNeutral500),
                                  )
                                ])),
                          ),

                          IconButton(
                              onPressed: () {
                                GoRouter.of(context).pop();
                              },
                              icon: const Icon(FeatherIcons.x, size: 22.0)),
                          // const Icon(FeatherIcons.x, color: kTitleColor, size: 30.0).onTap(() => Navigator.pop(context))
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 1.0,
                      color: kNeutral300,
                      height: 1,
                    ),

                    ///______date_&_category____________________________________
                    ResponsiveGridRow(children: [
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
                                    decoration: InputDecoration(
                                      suffixIcon: const Icon(
                                          IconlyLight.calendar,
                                          color: kGreyTextColor),
                                      contentPadding: const EdgeInsets.all(8.0),
                                      labelText: lang.S.of(context).expenseDate,
                                      hintText:
                                          lang.S.of(context).enterExpenseDate,
                                    ),
                                    child: Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  );
                                },
                              ).onTap(() => _selectDate(context)),
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
                                    decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.all(8.0),
                                        //labelText: 'Category'
                                        labelText: lang.S.of(context).category),
                                    child: Theme(
                                        data: ThemeData(
                                            highlightColor: dropdownItemColor,
                                            focusColor: dropdownItemColor,
                                            hoverColor: dropdownItemColor),
                                        child: DropdownButtonHideUnderline(
                                            child: getCategories())),
                                  );
                                },
                              ),
                            ),
                          )),
                    ]),

                    ///________Customer Selector (if Devolución Depósito)_______________________________
                    if (showCustomerSelector)
                      ResponsiveGridRow(children: [
                        ResponsiveGridCol(
                          xs: 12,
                          md: 12,
                          lg: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Consumer(
                              builder: (context, ref, child) {
                                final customerList = ref.watch(allCustomerProvider);
                                return customerList.when(
                                  data: (customers) {
                                    // Inicializar la lista filtrada si está vacía
                                    if (filteredCustomers.isEmpty && customers.isNotEmpty) {
                                      filteredCustomers = customers;
                                    }
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Campo de búsqueda
                                        TextFormField(
                                          controller: customerSearchController,
                                          focusNode: customerSearchFocus,
                                          decoration: InputDecoration(
                                            labelText: 'Cliente para Devolución',
                                            hintText: 'Buscar por nombre o teléfono...',
                                            prefixIcon: const Icon(Icons.search),
                                            suffixIcon: selectedCustomer != null
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear),
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedCustomer = null;
                                                        customerSearchController.clear();
                                                        showCustomerDropdown = false;
                                                        // Limpiar el campo "Gasto para" cuando se deselecciona el cliente
                                                        if (showCustomerSelector) {
                                                          expanseForNameController.clear();
                                                        }
                                                      });
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            filterCustomers(value, customers);
                                          },
                                          onTap: () {
                                            filterCustomers(customerSearchController.text, customers);
                                          },
                                        ),
                                        
                                        // Cliente seleccionado
                                        if (selectedCustomer != null)
                                          Container(
                                            margin: const EdgeInsets.only(top: 8.0),
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8.0),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        selectedCustomer!.customerName,
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      if (selectedCustomer!.phoneNumber.isNotEmpty)
                                                        Text(
                                                          selectedCustomer!.phoneNumber,
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
                                        // Lista de resultados
                                        if (showCustomerDropdown && filteredCustomers.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4.0),
                                            constraints: const BoxConstraints(maxHeight: 200),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8.0),
                                              border: Border.all(color: Colors.grey[300]!),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withValues(alpha: 0.2),
                                                  spreadRadius: 1,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: filteredCustomers.length,
                                              itemBuilder: (context, index) {
                                                final customer = filteredCustomers[index];
                                                return ListTile(
                                                  leading: const Icon(Icons.person_outline),
                                                  title: Text(customer.customerName),
                                                  subtitle: customer.phoneNumber.isNotEmpty 
                                                      ? Text(customer.phoneNumber) 
                                                      : null,
                                                  onTap: () {
                                                    setState(() {
                                                      selectedCustomer = customer;
                                                      customerSearchController.text = customer.customerName;
                                                      showCustomerDropdown = false;
                                                      // Auto-rellenar el campo "Gasto para" con el nombre del cliente
                                                      if (showCustomerSelector) {
                                                        expanseForNameController.text = 'Devolución depósito - ${customer.customerName}';
                                                      }
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        
                                        // Mensaje cuando no hay resultados
                                        if (showCustomerDropdown && filteredCustomers.isEmpty && customerSearchController.text.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4.0),
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8.0),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: const Text(
                                              'No se encontraron clientes con ese criterio',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (error, stack) => Text('Error: $error'),
                                );
                              },
                            ),
                          ),
                        ),
                      ]),

                    ///________payment Type_&_expanseFor_______________________________
                    ResponsiveGridRow(children: [
                      //-------------expense for----------------------
                      ResponsiveGridCol(
                          xs: 12,
                          md: 6,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: !showCustomerSelector,
                              readOnly: showCustomerSelector,
                              controller: expanseForNameController,
                              validator: (value) {
                                if (value.isEmptyOrNull) {
                                  // return 'Please Enter Name';
                                  return lang.S.of(context).pleaseEnterName;
                                }
                                return null;
                              },
                              onSaved: (value) {
                                expanseForNameController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              style: TextStyle(
                                color: showCustomerSelector ? Colors.grey[700] : null,
                              ),
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).expenseFor,
                                hintText: showCustomerSelector 
                                    ? 'Se mostrará el nombre del cliente seleccionado' 
                                    : lang.S.of(context).enterName,
                                fillColor: showCustomerSelector ? Colors.grey[100] : null,
                                filled: showCustomerSelector,
                                suffixIcon: showCustomerSelector
                                    ? Icon(
                                        Icons.lock_outline,
                                        color: Colors.grey[600],
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          )),
                      //---------------payment type------------------------
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
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText: lang.S.of(context).paymentType,
                                    ),
                                    child: Theme(
                                        data: ThemeData(
                                            highlightColor: dropdownItemColor,
                                            focusColor: dropdownItemColor,
                                            hoverColor: dropdownItemColor),
                                        child: DropdownButtonHideUnderline(
                                            child: getPaymentMethods())),
                                  );
                                },
                              ),
                            ),
                          )),
                    ]),

                    ///_______amount_reference_number______________________________________
                    ResponsiveGridRow(children: [
                      //------------amount----------------------
                      ResponsiveGridCol(
                          md: 6,
                          xs: 12,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              controller: expanseAmountController,
                              onChanged: (value) {
                                expenseAmount = value.replaceAll(',', '');
                                var formattedText =
                                    myFormat.format(int.parse(expenseAmount));
                                expanseAmountController.value =
                                    expanseAmountController.value.copyWith(
                                  text: formattedText,
                                  selection: TextSelection.collapsed(
                                      offset: formattedText.length),
                                );
                              },
                              validator: (value) {
                                if (expenseAmount.isEmptyOrNull) {
                                  //return 'please Inter Amount';
                                  return lang.S.of(context).pleaseInterAmount;
                                } else if (double.tryParse(expenseAmount) ==
                                    null) {
                                  //return 'Enter a valid Amount';
                                  return lang.S.of(context).enterAValidAmount;
                                }
                                return null;
                              },
                              onSaved: (value) {
                                expanseAmountController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).amount,
                                hintText: lang.S.of(context).enterAmount,
                              ),
                            ),
                          )),
                      //---------------reference-----------------------
                      ResponsiveGridCol(
                          md: 6,
                          xs: 12,
                          lg: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TextFormField(
                              showCursor: true,
                              controller: expanseRefController,
                              validator: (value) {
                                return null;
                              },
                              onSaved: (value) {
                                expanseRefController.text = value!;
                              },
                              cursorColor: kTitleColor,
                              decoration: InputDecoration(
                                labelText: lang.S.of(context).referenceNumber,
                                hintText:
                                    lang.S.of(context).enterReferenceNumber,
                              ),
                            ),
                          ))
                    ]),

                    ///_________note____________________________________________________
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        showCursor: true,
                        controller: expanseNoteController,
                        validator: (value) {
                          if (value == null) {
                            //return 'please Inter Amount';
                            return lang.S.of(context).pleaseInterAmount;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          expanseNoteController.text = value!;
                        },
                        cursorColor: kTitleColor,
                        decoration: InputDecoration(
                          labelText: lang.S.of(context).note,
                          hintText: lang.S.of(context).enterNote,
                        ),
                      ),
                    ),

                    ///___________buttons___________________________________________
                    const SizedBox(height: 10.0),
                    ResponsiveGridRow(rowSegments: 100, children: [
                      ResponsiveGridCol(
                          md: screenWidth < 768 ? 15 : 25,
                          xs: 100,
                          lg: 30,
                          child: const SizedBox.shrink()),
                      ResponsiveGridCol(
                        md: screenWidth < 768 ? 35 : 25,
                        xs: 100,
                        lg: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              GoRouter.of(context).pop();
                            },
                            child: Text(
                              lang.S.of(context).cancel,
                            ),
                          ),
                        ),
                      ),
                      ResponsiveGridCol(
                        md: screenWidth < 768 ? 35 : 25,
                        xs: 100,
                        lg: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            onPressed: saleButtonClicked
                                ? () {}
                                : () async {
                                    if (validateAndSave() &&
                                        selectedCategories != null &&
                                        selectedCategories!.isNotEmpty) {
                                      final String currentUserId = await getUserID();
                                      // Usar la misma lógica que en ventas para obtener el nombre del usuario
                                      final String currentUserName = isSubUser ? constSubUserTitle : 'Admin';
                                      
                                      ExpenseModel expense = ExpenseModel(
                                        expenseDate: selectedDate.toString(),
                                        category: selectedCategories.toString(),
                                        account: '',
                                        amount: expenseAmount,
                                        expanseFor:
                                            expanseForNameController.text,
                                        paymentType: selectedPaymentType,
                                        referenceNo: expanseRefController.text,
                                        note: expanseNoteController.text,
                                        userId: currentUserId,
                                        userName: currentUserName,
                                        customerId: showCustomerSelector ? selectedCustomer?.phoneNumber : null,
                                        customerName: showCustomerSelector ? selectedCustomer?.customerName : null,
                                        customerPhone: showCustomerSelector ? selectedCustomer?.phoneNumber : null,
                                      );
                                      try {
                                        setState(() {
                                          saleButtonClicked = true;
                                        });
                                        EasyLoading.show(
                                            status:
                                                '${lang.S.of(context).loading}...',
                                            dismissOnTap: false);

                                        // Guardar gasto en PostgreSQL API
                                        final response = await _apiService.post(
                                          'expenses',
                                          Map<String, dynamic>.from(expense.toJson()),
                                        );

                                        if (response.success) {
                                          EasyLoading.showSuccess(
                                              lang.S
                                                  .of(context)
                                                  .addedSuccessfully,
                                              duration: const Duration(
                                                  milliseconds: 500));

                                          // Registrar en auditoría
                                          await AuditService().logCreate(
                                            module: AuditModule.expenses,
                                            itemName: 'Gasto',
                                            itemId: expense.expenseDate,
                                            data: {
                                              'expanseFor': expense.expanseFor,
                                              'category': expense.category,
                                              'amount': expense.amount,
                                              'paymentType': expense.paymentType,
                                              'note': expense.note,
                                              'referenceNo': expense.referenceNo,
                                              'userId': expense.userId,
                                              'userName': expense.userName,
                                              'customerId': expense.customerId,
                                              'customerName': expense.customerName,
                                              'customerPhone': expense.customerPhone,
                                            },
                                          );

                                          // Generar ID único usando timestamp para evitar duplicados
                                          final uniqueId = 'EXP-${DateTime.now().millisecondsSinceEpoch}';

                                          DailyTransactionModel
                                              dailyTransaction =
                                              DailyTransactionModel(
                                            name: expense.expanseFor,
                                            date: expense.expenseDate,
                                            type: 'Expense',
                                            total: expense.amount.toDouble(),
                                            paymentIn: 0,
                                            paymentOut:
                                                expense.amount.toDouble(),
                                            remainingBalance:
                                                expense.amount.toDouble(),
                                            id: uniqueId,
                                            paymentType: expense.paymentType,
                                            sellerName: expense.userName ?? currentUserName,
                                            expenseModel: expense,
                                          );
                                          postDailyTransaction(
                                              dailyTransactionModel:
                                                  dailyTransaction);

                                          ref.refresh(expenseProvider);
                                          ref.refresh(dailyTransactionProvider);

                                          Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                            if (mounted) {
                                              GoRouter.of(context).pop();
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            saleButtonClicked = false;
                                          });
                                          EasyLoading.dismiss();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content:
                                                      Text(response.message ?? 'Error al guardar gasto')));
                                        }
                                      } catch (e) {
                                        setState(() {
                                          saleButtonClicked = false;
                                        });
                                        EasyLoading.dismiss();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(e.toString())));
                                      }
                                    } else {
                                      EasyLoading.showInfo(lang.S
                                          .of(context)
                                          .pleaseSelectACategory);
                                    }
                                  },
                            child: Text(
                              lang.S.of(context).saveAndPublish,
                            ),
                          ),
                          // ElevatedButton(
                          //     onPressed: saleButtonClicked
                          //         ? () {}
                          //         : () async {
                          //             if (validateAndSave() && selectedCategories != null && selectedCategories!.isNotEmpty) {
                          //               ExpenseModel expense = ExpenseModel(
                          //                 expenseDate: selectedDate.toString(),
                          //                 category: selectedCategories.toString(),
                          //                 account: '',
                          //                 amount: expenseAmount,
                          //                 expanseFor: expanseForNameController.text,
                          //                 paymentType: selectedPaymentType,
                          //                 referenceNo: expanseRefController.text,
                          //                 note: expanseNoteController.text,
                          //               );
                          //               try {
                          //                 setState(() {
                          //                   saleButtonClicked = true;
                          //                 });
                          //                 EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                          //                 final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Expense');
                          //                 await productInformationRef.push().set(expense.toJson());
                          //                 EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));
                          //
                          //                 ///________daily_transactionModel_________________________________________________________________________
                          //
                          //                 DailyTransactionModel dailyTransaction = DailyTransactionModel(
                          //                   name: expense.expanseFor,
                          //                   date: expense.expenseDate,
                          //                   type: 'Expense',
                          //                   total: expense.amount.toDouble(),
                          //                   paymentIn: 0,
                          //                   paymentOut: expense.amount.toDouble(),
                          //                   remainingBalance: expense.amount.toDouble(),
                          //                   id: expense.expenseDate,
                          //                   expenseModel: expense,
                          //                 );
                          //                 postDailyTransaction(dailyTransactionModel: dailyTransaction);
                          //
                          //                 ///____provider_refresh____________________________________________
                          //                 ref.refresh(expenseProvider);
                          //                 ref.refresh(dailyTransactionProvider);
                          //
                          //                 Future.delayed(const Duration(milliseconds: 100), () {
                          //                   // const Product().launch(context, isNewTask: true);
                          //                   GoRouter.of(context).pop();
                          //                   context.go('/expense');
                          //                   // Navigator.pop(context);
                          //                   // Navigator.of(context).pushReplacementNamed(ExpensesList.route);
                          //                 });
                          //               } catch (e) {
                          //                 setState(() {
                          //                   saleButtonClicked = false;
                          //                 });
                          //                 EasyLoading.dismiss();
                          //                 //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          //               }
                          //             } else {
                          //               //EasyLoading.showInfo('Please select a category');
                          //               EasyLoading.showInfo(lang.S.of(context).pleaseSelectACategory);
                          //             }
                          //           },
                          //     child: Text(
                          //       lang.S.of(context).saveAndPublish,
                          //     )),
                        ),
                      ),
                      ResponsiveGridCol(
                          md: screenWidth < 768 ? 15 : 25,
                          xs: 100,
                          lg: 30,
                          child: const SizedBox.shrink()),
                    ]),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
