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
import 'package:salespro_admin/Provider/customer_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:salespro_admin/model/expense_model.dart';
import 'package:salespro_admin/model/customer_model.dart';

import '../../const.dart';
import '../../model/expense_category_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';

class ExpenseEdit extends StatefulWidget {
  const ExpenseEdit({super.key, required this.expenseModel});

  final ExpenseModel expenseModel;

  @override
  State<ExpenseEdit> createState() => _ExpenseEditState();
}

class _ExpenseEditState extends State<ExpenseEdit> {
  void showCategoryPopUp() {
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return Dialog(
              surfaceTintColor: Colors.white,
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
        //'Cash',
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

  String expenseKey = '';
  final ApiService _apiService = ApiService();

  void getExpenseKey() async {
    try {
      final response = await _apiService.get('expenses', queryParams: {
        'expanseFor': widget.expenseModel.expanseFor,
        'amount': widget.expenseModel.amount,
        'expenseDate': widget.expenseModel.expenseDate,
        'limit': '1',
      });
      if (response.success && response.data != null) {
        final expenses = response.data['expenses'] as List<dynamic>? ?? [];
        if (expenses.isNotEmpty) {
          final expenseData = Map<String, dynamic>.from(expenses.first);
          expenseKey = expenseData['id']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo expenseKey: $e');
    }
  }

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
            showCustomerDropdown = false;
            // Restaurar el campo "Gasto para" al valor original
            expanseForNameController.text = widget.expenseModel.expanseFor;
          } else if (!wasShowingCustomerSelector && showCustomerSelector && selectedCustomer != null) {
            // Si ahora muestra el selector y hay un cliente seleccionado, actualizar el campo
            expanseForNameController.text = 'Devolución depósito - ${selectedCustomer!.customerName}';
          }
        });
      },
    );
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

    setState(() {
      selectedCategories = widget.expenseModel.category;
    });
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

  TextEditingController expanseForNameController = TextEditingController();
  TextEditingController expanseAmountController = TextEditingController();
  TextEditingController expanseNoteController = TextEditingController();
  TextEditingController expanseRefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    expanseForNameController.text = widget.expenseModel.expanseFor;
    expanseAmountController.text = widget.expenseModel.amount;
    expanseNoteController.text = widget.expenseModel.note;
    expanseRefController.text = widget.expenseModel.referenceNo;
    selectedDate = DateTime.parse(widget.expenseModel.expenseDate);
    selectedPaymentType = widget.expenseModel.paymentType;
    getExpenseKey();
    category().then((_) {
      // Después de cargar las categorías, establecer la categoría actual
      setState(() {
        selectedCategories = widget.expenseModel.category;
        // Verificar si es una categoría de devolución
        showCustomerSelector = selectedCategories?.toLowerCase().contains('devolución') == true || 
                              selectedCategories?.toLowerCase().contains('devolucion') == true ||
                              selectedCategories?.toLowerCase().contains('depósito') == true ||
                              selectedCategories?.toLowerCase().contains('deposito') == true ||
                              selectedCategories?.toLowerCase().contains('refund') == true ||
                              selectedCategories?.toLowerCase().contains('deposit') == true;
        
        // Si ya tiene cliente asignado, establecerlo
        if (widget.expenseModel.customerName != null && widget.expenseModel.customerName!.isNotEmpty) {
          customerSearchController.text = widget.expenseModel.customerName!;
          // Si es una devolución con cliente, mantener el formato del campo "Gasto para"
          if (showCustomerSelector) {
            expanseForNameController.text = widget.expenseModel.expanseFor;
          }
        }
      });
    });
    
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
    expanseForNameController.dispose();
    expanseAmountController.dispose();
    expanseNoteController.dispose();
    expanseRefController.dispose();
    customerSearchController.dispose();
    customerSearchFocus.dispose();
    super.dispose();
  }

  ScrollController mainScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          backgroundColor: kDarkWhite,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                          Text(
                            'Edit Expense',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                GoRouter.of(context).pop();
                              },
                              icon: const Icon(FeatherIcons.x, size: 22.0)),
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
                      //--------------date picker----------------
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
                      //---------------category------------------
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
                                                FeatherIcons.plus,
                                                color: kTitleColor)
                                            .onTap(() => showCategoryPopUp()),
                                        contentPadding:
                                            const EdgeInsets.all(8.0),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
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
                          ))
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
                                    
                                    // Si tiene cliente del modelo, buscarlo en la lista
                                    if (selectedCustomer == null && widget.expenseModel.customerId != null) {
                                      try {
                                        selectedCustomer = customers.firstWhere(
                                          (c) => c.phoneNumber == widget.expenseModel.customerId
                                        );
                                      } catch (e) {
                                        // Cliente no encontrado en la lista
                                        selectedCustomer = null;
                                      }
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
                                                        // Restaurar el campo "Gasto para" al valor original cuando se deselecciona el cliente
                                                        if (showCustomerSelector) {
                                                          expanseForNameController.text = widget.expenseModel.expanseFor;
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
                      ///___________________Expanse for_______________________________
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
                                //return 'Please Enter Name';
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
                        ),
                      ),

                      ///________PaymentType__________________________________
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
                                      suffixIcon: const Icon(FeatherIcons.plus,
                                              color: kTitleColor)
                                          .onTap(() => showCategoryPopUp()),
                                      contentPadding: const EdgeInsets.all(8.0),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                      labelText:
                                          lang.S.of(context).paymentType),
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
                        ),
                      ),
                    ]),
                    // Row(
                    //   children: [
                    //     ///___________________Expanse for_______________________________
                    //     Expanded(
                    //       child: TextFormField(
                    //         showCursor: true,
                    //         controller: expanseForNameController,
                    //         validator: (value) {
                    //           if (value.isEmptyOrNull) {
                    //             //return 'Please Enter Name';
                    //             return lang.S.of(context).pleaseEnterName;
                    //           }
                    //           return null;
                    //         },
                    //         onSaved: (value) {
                    //           expanseForNameController.text = value!;
                    //         },
                    //         cursorColor: kTitleColor,
                    //         decoration: kInputDecoration.copyWith(
                    //           errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                    //           labelText: lang.S.of(context).expenseFor,
                    //           labelStyle: kTextStyle.copyWith(color: kTitleColor),
                    //           hintText: lang.S.of(context).enterName,
                    //           hintStyle: kTextStyle.copyWith(color: kGreyTextColor),
                    //         ),
                    //       ),
                    //     ),
                    //
                    //     const SizedBox(width: 20),
                    //
                    //     ///________PaymentType__________________________________
                    //     Expanded(
                    //       child: FormField(
                    //         builder: (FormFieldState<dynamic> field) {
                    //           return InputDecorator(
                    //             decoration: InputDecoration(
                    //                 enabledBorder: const OutlineInputBorder(
                    //                   borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    //                   borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                    //                 ),
                    //                 suffixIcon: const Icon(FeatherIcons.plus, color: kTitleColor).onTap(() => showCategoryPopUp()),
                    //                 contentPadding: const EdgeInsets.all(8.0),
                    //                 floatingLabelBehavior: FloatingLabelBehavior.always,
                    //                 labelText: lang.S.of(context).paymentType),
                    //             child: Theme(
                    //                 data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                    //                 child: DropdownButtonHideUnderline(child: getPaymentMethods())),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 20.0),

                    ///_______amount_reference_number______________________________________
                    ResponsiveGridRow(children: [
                      ///_________________Amount_____________________________
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
                        lg: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextFormField(
                            showCursor: true,
                            controller: expanseAmountController,
                            validator: (value) {
                              if (value.isEmptyOrNull) {
                                //return 'please Inter Amount';
                                return lang.S.of(context).pleaseInterAmount;
                              } else if (double.tryParse(value!) == null) {
                                // return 'Enter a valid Amount';
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
                              hintText: lang.S.of(context).enterYOurAmount,
                            ),
                          ),
                        ),
                      ),

                      ///_______reference_________________________________
                      ResponsiveGridCol(
                        xs: 12,
                        md: 6,
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
                              labelText: lang.S.of(context).referenceNo,
                              hintText: lang.S.of(context).enterReferenceNumber,
                            ),
                          ),
                        ),
                      ),
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
                              onPressed: () async {
                                if (validateAndSave()) {
                                  final String currentUserId = await getUserID();
                                  // Usar la misma lógica que en ventas para obtener el nombre del usuario
                                  final String currentUserName = isSubUser ? constSubUserTitle : 'Admin';
                                  
                                  ExpenseModel expense = ExpenseModel(
                                    expenseDate: selectedDate.toString(),
                                    category: selectedCategories.toString(),
                                    account: '',
                                    amount: expanseAmountController.text,
                                    expanseFor: expanseForNameController.text,
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
                                    EasyLoading.show(
                                        status:
                                            '${lang.S.of(context).loading}...',
                                        dismissOnTap: false);

                                    // Actualizar gasto en PostgreSQL API
                                    final response = await _apiService.put(
                                      'expenses/$expenseKey',
                                      Map<String, dynamic>.from(expense.toJson()),
                                    );

                                    if (!response.success) {
                                      throw Exception(response.message ?? 'Error al actualizar gasto');
                                    }
                                    
                                    // Registrar en auditoría la actualización
                                    await AuditService().logUpdate(
                                      module: AuditModule.expenses,
                                      itemName: 'Gasto',
                                      itemId: expenseKey,
                                      beforeData: {
                                        'expanseFor': widget.expenseModel.expanseFor,
                                        'category': widget.expenseModel.category,
                                        'amount': widget.expenseModel.amount,
                                        'paymentType': widget.expenseModel.paymentType,
                                        'note': widget.expenseModel.note,
                                        'referenceNo': widget.expenseModel.referenceNo,
                                      },
                                      afterData: {
                                        'expanseFor': expense.expanseFor,
                                        'category': expense.category,
                                        'amount': expense.amount,
                                        'paymentType': expense.paymentType,
                                        'note': expense.note,
                                        'referenceNo': expense.referenceNo,
                                      },
                                    );
                                    
                                    EasyLoading.showSuccess(
                                        lang.S.of(context).addedSuccessfully,
                                        duration:
                                            const Duration(milliseconds: 500));

                                    ///____provider_refresh____________________________________________
                                    // ignore: unused_result
                                    ref.refresh(expenseProvider);

                                    Future.delayed(
                                        const Duration(milliseconds: 100), () {
                                      // const Product().launch(context, isNewTask: true);
                                      GoRouter.of(context).pop();
                                    });
                                  } catch (e) {
                                    EasyLoading.dismiss();
                                    //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                  }
                                }
                              },
                              child: Text(
                                lang.S.of(context).saveAndPublish,
                              )),
                        ),
                      ),
                      ResponsiveGridCol(
                          md: screenWidth < 768 ? 15 : 25,
                          xs: 100,
                          lg: 30,
                          child: const SizedBox.shrink()),
                    ]),
                    // Row(
                    //   mainAxisSize: MainAxisSize.max,
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     ///_______cancel__________________________________________________
                    //
                    //     GestureDetector(
                    //       onTap: () {
                    //         Navigator.pop(context);
                    //       },
                    //       child: Container(
                    //         width: 120,
                    //         padding: const EdgeInsets.all(10.0),
                    //         decoration: BoxDecoration(
                    //           borderRadius: BorderRadius.circular(5.0),
                    //           color: Colors.red,
                    //         ),
                    //         child: Center(
                    //           child: Text(
                    //             lang.S.of(context).cancel,
                    //             style: kTextStyle.copyWith(color: kWhite),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 20),
                    //
                    //     ///________save__________________________________________________
                    //     Container(
                    //       width: 120,
                    //       padding: const EdgeInsets.all(10.0),
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(5.0),
                    //         color: kGreenTextColor,
                    //       ),
                    //       child: Center(
                    //         child: Text(
                    //           lang.S.of(context).saveAndPublish,
                    //           style: kTextStyle.copyWith(color: kWhite),
                    //         ),
                    //       ),
                    //     ).onTap(() async {
                    //       if (validateAndSave()) {
                    //         ExpenseModel expense = ExpenseModel(
                    //           expenseDate: selectedDate.toString(),
                    //           category: selectedCategories.toString(),
                    //           account: '',
                    //           amount: expanseAmountController.text,
                    //           expanseFor: expanseForNameController.text,
                    //           paymentType: selectedPaymentType,
                    //           referenceNo: expanseRefController.text,
                    //           note: expanseNoteController.text,
                    //         );
                    //         try {
                    //           EasyLoading.show(status: '${lang.S.of(context).loading}...', dismissOnTap: false);
                    //           final DatabaseReference productInformationRef = FirebaseDatabase.instance.ref().child(await getUserID()).child('Expense').child(expenseKey);
                    //           await productInformationRef.set(expense.toJson());
                    //           EasyLoading.showSuccess(lang.S.of(context).addedSuccessfully, duration: const Duration(milliseconds: 500));
                    //
                    //           ///____provider_refresh____________________________________________
                    //           ref.refresh(expenseProvider);
                    //
                    //           Future.delayed(const Duration(milliseconds: 100), () {
                    //             // const Product().launch(context, isNewTask: true);
                    //             Navigator.pop(context);
                    //           });
                    //         } catch (e) {
                    //           EasyLoading.dismiss();
                    //           //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    //         }
                    //       }
                    //     }),
                    //   ],
                    // ),
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
