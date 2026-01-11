import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Provider/all_expanse_provider.dart';
import 'package:salespro_admin/commas.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/api_service.dart';

import '../../const.dart';
import '../../model/expense_model.dart';
import '../Widgets/Constant Data/constant.dart';
import '../Widgets/Constant Data/export_button.dart';
import '../currency/currency_provider.dart';
import 'expense_details.dart';
import '../../services/deletion_password_service.dart';
import '../../services/audit_service.dart';
import '../../model/audit_model.dart';
import '../../Provider/daily_transaction_provider.dart';
import '../../model/daily_transaction_model.dart';

class ExpensesList extends StatefulWidget {
  const ExpensesList({Key? key}) : super(key: key);

  // static const String route = '/expenses';

  @override
  State<ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends State<ExpensesList> {
  String searchItem = '';
  DateTime selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final ApiService _apiService = ApiService();

  List<String> get month => [
        'Hoy',
        'Este Mes',
        'Mes Pasado',
        'Últimos 6 Meses',
        'Este Año',
      ];

  late String selectedMonth = month.first;

  DropdownButton<String> getMonth() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in month) {
      var item = DropdownMenuItem(
        value: des,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(des),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      isExpanded: true,
      items: dropDownItems,
      value: selectedMonth,
      onChanged: (value) {
        setState(() {
          selectedMonth = value!;
          switch (selectedMonth) {
            case 'Hoy':
              {
                final now = DateTime.now();
                selectedDate = DateTime(now.year, now.month, now.day);
                selected2ndDate = DateTime(now.year, now.month, now.day);
              }
              break;
            case 'Este Mes':
              {
                var date = DateTime(DateTime.now().year, DateTime.now().month, 1).toString();

                selectedDate = DateTime.parse(date);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Mes Pasado':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
                selected2ndDate = DateTime(DateTime.now().year, DateTime.now().month, 0);
              }
              break;
            case 'Últimos 6 Meses':
              {
                selectedDate = DateTime(DateTime.now().year, DateTime.now().month - 6, 1);
                selected2ndDate = DateTime.now();
              }
              break;
            case 'Este Año':
              {
                selectedDate = DateTime(DateTime.now().year, 1, 1);
                selected2ndDate = DateTime.now();
              }
              break;
          }
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime selected2ndDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Future<void> _selectedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selected2ndDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selected2ndDate) {
      setState(() {
        selected2ndDate = picked;
      });
    }
  }

  double calculateAllExpense({required List<ExpenseModel> allExpense}) {
    double totalExpense = 0;
    for (var element in allExpense) {
      totalExpense += double.tryParse(element.amount) ?? 0.0;
    }

    return totalExpense;
  }

  ScrollController mainScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
  }
  
  Future<void> _showDeleteConfirmation({
    required BuildContext context,
    required ExpenseModel expense,
    required WidgetRef ref,
  }) async {
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de advertencia
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  'Eliminar Gasto/Devolución',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTitleColor,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Información del gasto
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Concepto:'),
                          Flexible(
                            child: Text(
                              expense.expanseFor,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monto:'),
                          Text(
                            '\$${expense.amount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha:'),
                          Text(
                            expense.expenseDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (expense.customerName != null && expense.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cliente:'),
                            Flexible(
                              child: Text(
                                expense.customerName!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Campo de contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña de autorización',
                    hintText: 'Ingrese la contraseña para eliminar',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Mensaje de advertencia
                const Text(
                  'Esta acción no se puede deshacer',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          lang.S.of(context).cancel,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          // Verificar contraseña con Firebase
                          final isValid = await DeletionPasswordService.validatePassword(
                            passwordController.text,
                          );

                          if (isValid) {
                            Navigator.pop(dialogContext);
                            await _deleteExpense(expense, ref);
                          } else {
                            EasyLoading.showError('Contraseña incorrecta');
                          }
                        },
                        child: const Text('Eliminar'),
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
  
  Future<void> _deleteDailyTransaction(ExpenseModel expense) async {
    try {
      // Buscar y eliminar la transacción diaria correspondiente usando API
      final response = await _apiService.get('daily-transactions', queryParams: {
        'type': 'Expense',
      });

      if (response.success && response.data != null) {
        final transactions = response.data['daily_transactions'] as List<dynamic>? ??
            response.data['transactions'] as List<dynamic>? ?? [];

        for (var element in transactions) {
          final transactionData = Map<String, dynamic>.from(element);
          final transaction = DailyTransactionModel.fromJson(transactionData);

          // Comparar por tipo, fecha y modelo de gasto
          if (transaction.type == 'Expense' &&
              transaction.expenseModel != null &&
              transaction.expenseModel!.expanseFor == expense.expanseFor &&
              transaction.expenseModel!.amount == expense.amount &&
              transaction.expenseModel!.expenseDate == expense.expenseDate) {

            // Eliminar la transacción diaria usando API
            final transactionId = transactionData['id']?.toString();
            if (transactionId != null) {
              await _apiService.delete('daily-transactions/$transactionId');
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error eliminando transacción diaria: $e');
    }
  }
  
  Future<void> _updateShopBalance(ExpenseModel expense) async {
    try {
      // Obtener el balance actual usando API
      final response = await _apiService.get('business-settings');

      if (response.success && response.data != null) {
        final settings = response.data['settings'] ?? response.data;
        double currentBalance = double.tryParse(settings['remainingShopBalance']?.toString() ?? '0') ?? 0.0;

        // Al eliminar un gasto, sumar el monto de vuelta al balance
        double newBalance = currentBalance + double.parse(expense.amount);

        // Actualizar el balance usando API
        await _apiService.put('business-settings', {
          'remainingShopBalance': newBalance,
        });
      }
    } catch (e) {
      debugPrint('Error actualizando balance de la tienda: $e');
    }
  }
  
  Future<void> _deleteExpense(ExpenseModel expense, WidgetRef ref) async {
    try {
      EasyLoading.show(status: 'Eliminando...');

      // Buscar la key del gasto usando API
      String? expenseKey;
      final response = await _apiService.get('expenses', queryParams: {
        'expanseFor': expense.expanseFor,
        'amount': expense.amount,
        'expenseDate': expense.expenseDate,
        'category': expense.category,
      });

      if (response.success && response.data != null) {
        final expenses = response.data['expenses'] as List<dynamic>? ?? [];
        for (var element in expenses) {
          final expenseData = Map<String, dynamic>.from(element);
          // Comparar por múltiples campos para asegurar que es el gasto correcto
          if (expenseData['expanseFor'] == expense.expanseFor &&
              expenseData['amount']?.toString() == expense.amount &&
              expenseData['expenseDate'] == expense.expenseDate &&
              expenseData['category'] == expense.category) {
            expenseKey = expenseData['id']?.toString();
            break;
          }
        }
      }

      if (expenseKey != null) {
        // Preparar datos para auditoría
        final beforeData = {
          'expenseKey': expenseKey,
          'expanseFor': expense.expanseFor,
          'amount': expense.amount,
          'category': expense.category,
          'expenseDate': expense.expenseDate,
          'paymentType': expense.paymentType,
          'referenceNo': expense.referenceNo,
          'note': expense.note,
          if (expense.customerName != null) 'customerName': expense.customerName,
          if (expense.customerPhone != null) 'customerPhone': expense.customerPhone,
          if (expense.customerId != null) 'customerId': expense.customerId,
        };

        // Eliminar el gasto usando API
        await _apiService.delete('expenses/$expenseKey');

        // Eliminar también de Daily Transaction
        await _deleteDailyTransaction(expense);

        // Actualizar el balance de la tienda
        await _updateShopBalance(expense);

        // Registrar en auditoría
        await AuditService().logAction(
          action: AuditAction.delete,
          module: AuditModule.expenses,
          description: 'Eliminó el gasto "${expense.expanseFor}" por \$${expense.amount}${expense.customerName != null ? " (Cliente: ${expense.customerName})" : ""}',
          beforeData: beforeData,
          afterData: null,
        );

        // Refrescar la lista
        ref.invalidate(expenseProvider);
        ref.invalidate(dailyTransactionProvider);

        EasyLoading.showSuccess('Gasto eliminado correctamente');
      } else {
        EasyLoading.showError('No se pudo encontrar el gasto');
      }
    } catch (e) {
      EasyLoading.showError('Error al eliminar: $e');
    }
  }

  final _horizontalScroll = ScrollController();
  int _expensePerPage = 10; // Default number of items to display
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final currencyProvider = pro.Provider.of<CurrencyProvider>(context);
    final globalCurrency = currencyProvider.currency ?? '\$';
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Consumer(
        builder: (context, ref, child) {
          final expenses = ref.watch(expenseProvider);
          return expenses.when(data: (allExpenses) {
            List<ExpenseModel> reverseAllExpense = allExpenses.reversed.toList();
            List<ExpenseModel> showExpense = [];
            for (var element in reverseAllExpense) {
              try {
                DateTime expenseDate = DateTime.parse(element.expenseDate);
                // Normalizar la fecha del gasto a solo fecha (sin hora)
                DateTime expenseDateOnly = DateTime(expenseDate.year, expenseDate.month, expenseDate.day);
                
                bool matchesSearch = searchItem.isEmpty || element.expanseFor.toLowerCase().contains(searchItem.toLowerCase());
                bool matchesDateStart = selectedDate.isBefore(expenseDateOnly) || selectedDate.isAtSameMomentAs(expenseDateOnly);
                bool matchesDateEnd = selected2ndDate.isAfter(expenseDateOnly) || selected2ndDate.isAtSameMomentAs(expenseDateOnly);
                
                if (matchesSearch && matchesDateStart && matchesDateEnd) {
                  showExpense.add(element);
                }
              } catch (e) {
                // Error parseando fecha
              }
            }

            final pages = (showExpense.length / _expensePerPage).ceil();
            final startIndex = (_currentPage - 1) * _expensePerPage;
            final endIndex = startIndex + _expensePerPage;
            final paginatedList = showExpense.sublist(
              startIndex,
              endIndex > showExpense.length ? showExpense.length : endIndex,
            );

            return Scaffold(
                backgroundColor: kDarkWhite,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: kWhite,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveGridRow(rowSegments: 100, children: [
                              ResponsiveGridCol(
                                  xs: 100,
                                  md: 30,
                                  lg: 15,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 48,
                                      child: FormField(
                                        builder: (FormFieldState<dynamic> field) {
                                          return InputDecorator(
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                            child: Theme(data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor), child: DropdownButtonHideUnderline(child: getMonth())),
                                          );
                                        },
                                      ),
                                    ),
                                  )),
                              ResponsiveGridCol(
                                xs: 100,
                                md: 50,
                                lg: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kNeutral400)),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 48,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(shape: BoxShape.rectangle, color: kGreyTextColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0))),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                lang.S.of(context).between,
                                                style: kTextStyle.copyWith(color: kWhite),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),
                                          Text(
                                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                          ).onTap(() => _selectDate(context)),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            lang.S.of(context).to,
                                            style: kTextStyle.copyWith(color: kTitleColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            '${selected2ndDate.day}/${selected2ndDate.month}/${selected2ndDate.year}',
                                            style: kTextStyle.copyWith(color: kTitleColor),
                                          ).onTap(() => _selectedDate(context)),
                                          const SizedBox(width: 10.0),
                                        ],
                                      )),
                                ),
                              )
                            ]),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Container(
                                padding: const EdgeInsets.only(left: 10.0, right: 20.0, top: 10.0, bottom: 10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: const Color(0xFFCFF4E3),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$globalCurrency ${myFormat.format(calculateAllExpense(allExpense: showExpense))}',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                                    ),
                                    Text(
                                      lang.S.of(context).totalExpense,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        // padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0), color: kWhite),
                        child: Column(
                          children: [
                            ResponsiveGridRow(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              ResponsiveGridCol(
                                xs: 12,
                                md: screenWidth < 850 ? 4 : 6,
                                lg: screenWidth < 1520 ? 6 : 8,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    lang.S.of(context).expensesList,
                                    //'Expenses List',
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 6,
                                md: screenWidth < 850 ? 4 : 3,
                                lg: screenWidth < 1520 ? 3 : 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    onPressed: () => context.go('/expense/expense-category'),
                                    child: Text(
                                      lang.S.of(context).expenseCategory,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 6,
                                md: screenWidth < 850 ? 4 : 3,
                                lg: screenWidth < 1520 ? 3 : 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton.icon(
                                      onPressed: () => context.go('/expense/new-expense'),
                                      icon: const Icon(FeatherIcons.plus, color: kWhite, size: 18.0),
                                      label: Text(
                                        lang.S.of(context).newExpenses,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                ),
                              ),
                            ]),
                            const Divider(
                              thickness: 1.0,
                              color: kNeutral300,
                              height: 1,
                            ),
                            const SizedBox(height: 10),

                            ///___________search________________________________________________-
                            ResponsiveGridRow(rowSegments: 100, children: [
                              ResponsiveGridCol(
                                xs: screenWidth < 360
                                    ? 50
                                    : screenWidth > 430
                                        ? 33
                                        : 40,
                                md: screenWidth < 768
                                    ? 24
                                    : screenWidth < 950
                                        ? 20
                                        : 15,
                                lg: screenWidth < 1700 ? 15 : 10,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 48,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: kNeutral300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                            child: Text(
                                          'Show-',
                                          style: theme.textTheme.bodyLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                        DropdownButton<int>(
                                          isDense: true,
                                          padding: EdgeInsets.zero,
                                          underline: const SizedBox(),
                                          value: _expensePerPage,
                                          icon: const Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.black,
                                          ),
                                          items: [10, 20, 50, 100, -1].map<DropdownMenuItem<int>>((int value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(
                                                value == -1 ? "All" : value.toString(),
                                                style: theme.textTheme.bodyLarge,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (int? newValue) {
                                            setState(() {
                                              if (newValue == -1) {
                                                _expensePerPage = -1; // Set to -1 for "All"
                                              } else {
                                                _expensePerPage = newValue ?? 10;
                                              }
                                              _currentPage = 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveGridCol(
                                xs: 100,
                                md: 60,
                                lg: 35,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: TextFormField(
                                    showCursor: true,
                                    cursorColor: kTitleColor,
                                    onChanged: (value) {
                                      setState(() {
                                        searchItem = value;
                                      });
                                    },
                                    keyboardType: TextInputType.name,
                                    decoration: kInputDecoration.copyWith(
                                      contentPadding: const EdgeInsets.all(10.0),
                                      //hintText: ('Search by Invoice...'),
                                      hintText: ('${lang.S.of(context).searchByInvoice}...'),
                                      suffixIcon: const Icon(
                                        FeatherIcons.search,
                                        color: kTitleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),

                            ///__________expense_LIst____________________________________________________________________

                            const SizedBox(height: 10.0),
                            showExpense.isNotEmpty
                                ? Column(
                                    children: [
                                      LayoutBuilder(
                                        builder: (context, constrains) {
                                          return Scrollbar(
                                            controller: _horizontalScroll,
                                            thumbVisibility: true,
                                            radius: const Radius.circular(8),
                                            thickness: 8,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller: _horizontalScroll,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: constrains.maxWidth,
                                                ),
                                                child: Theme(
                                                  data: theme.copyWith(
                                                    dividerColor: Colors.transparent,
                                                    dividerTheme: const DividerThemeData(color: Colors.transparent),
                                                  ),
                                                  child: DataTable(
                                                      border: const TableBorder(
                                                        horizontalInside: BorderSide(
                                                          width: 1,
                                                          color: kNeutral300,
                                                        ),
                                                      ),
                                                      dataRowColor: const WidgetStatePropertyAll(Colors.white),
                                                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F3FF)),
                                                      showBottomBorder: false,
                                                      dividerThickness: 0.0,
                                                      headingTextStyle: theme.textTheme.titleMedium,
                                                      columns: [
                                                        DataColumn(label: Text(lang.S.of(context).SL)),
                                                        DataColumn(label: Text(lang.S.of(context).date)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).createdBy)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).expenseFor)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).category)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: const Text('Cliente')),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).note)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).paymentType)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).amount)),
                                                        DataColumn(headingRowAlignment: MainAxisAlignment.center, label: Text(lang.S.of(context).setting)),
                                                      ],
                                                      rows: List.generate(paginatedList.length, (index) {
                                                        return DataRow(cells: [
                                                          ///______________S.L__________________________________________________
                                                          DataCell(
                                                            Text('${startIndex + index + 1}'),
                                                          ),

                                                          ///______________Date__________________________________________________
                                                          DataCell(
                                                            Text(
                                                              paginatedList[index].expenseDate.substring(0, 10),
                                                            ),
                                                          ),

                                                          ///____________Created By_________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                paginatedList[index].userName ?? 'Unknown',
                                                              ),
                                                            ),
                                                          ),

                                                          ///____________Expense For_________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                paginatedList[index].expanseFor,
                                                              ),
                                                            ),
                                                          ),

                                                          ///______Category___________________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                paginatedList[index].category,
                                                              ),
                                                            ),
                                                          ),

                                                          ///______Cliente (para devoluciones)___________________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: paginatedList[index].customerName != null && paginatedList[index].customerName!.isNotEmpty
                                                                  ? Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          paginatedList[index].customerName!,
                                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                                        ),
                                                                        if (paginatedList[index].customerPhone != null && paginatedList[index].customerPhone!.isNotEmpty)
                                                                          Text(
                                                                            paginatedList[index].customerPhone!,
                                                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                                          ),
                                                                      ],
                                                                    )
                                                                  : const Text('-'),
                                                            ),
                                                          ),

                                                          ///___________note______________________________________________

                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                paginatedList[index].note.toString(),
                                                              ),
                                                            ),
                                                          ),

                                                          ///___________Payment tYpe____________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                paginatedList[index].paymentType.toString(),
                                                              ),
                                                            ),
                                                          ),

                                                          ///___________Amount____________________________________________________

                                                          DataCell(
                                                            Center(
                                                              child: Text(
                                                                '$globalCurrency${myFormat.format(int.tryParse(paginatedList[index].amount.toString()) ?? 0)}',
                                                              ),
                                                            ),
                                                          ),

                                                          ///_______________actions_________________________________________________
                                                          DataCell(
                                                            Center(
                                                              child: SizedBox(
                                                                width: 25,
                                                                child: Theme(
                                                                  data: ThemeData(highlightColor: dropdownItemColor, focusColor: dropdownItemColor, hoverColor: dropdownItemColor),
                                                                  child: PopupMenuButton(
                                                                    surfaceTintColor: Colors.white,
                                                                    padding: EdgeInsets.zero,
                                                                    itemBuilder: (BuildContext bc) => [
                                                                      PopupMenuItem(
                                                                        onTap: () {
                                                                          showDialog(
                                                                            barrierDismissible: false,
                                                                            context: context,
                                                                            builder: (BuildContext context) {
                                                                              return StatefulBuilder(
                                                                                builder: (context, setStates) {
                                                                                  return Dialog(
                                                                                    surfaceTintColor: Colors.white,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(20.0),
                                                                                    ),
                                                                                    child: ExpenseDetails(expense: showExpense[index], manuContext: bc),
                                                                                  );
                                                                                },
                                                                              );
                                                                            },
                                                                          );
                                                                        },
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(Icons.remove_red_eye_outlined, size: 22.0, color: kGreyTextColor),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).view,
                                                                              style: theme.textTheme.bodyLarge?.copyWith(color: kGreyTextColor),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),

                                                                      ///____________edit___________________________________________
                                                                      PopupMenuItem(
                                                                        onTap: () {
                                                                          GoRouter.of(context).push(
                                                                            '/expense/edit-expense',
                                                                            extra: showExpense[index], // Pass the expense model as extra
                                                                          );
                                                                        },
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(IconlyLight.edit, size: 22.0, color: kGreyTextColor),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).edit,
                                                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                                                color: kGreyTextColor,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      
                                                                      ///____________delete___________________________________________
                                                                      PopupMenuItem(
                                                                        onTap: () {
                                                                          _showDeleteConfirmation(
                                                                            context: context,
                                                                            expense: showExpense[index],
                                                                            ref: ref,
                                                                          );
                                                                        },
                                                                        child: Row(
                                                                          children: [
                                                                            const Icon(IconlyLight.delete, size: 22.0, color: Colors.red),
                                                                            const SizedBox(width: 4.0),
                                                                            Text(
                                                                              lang.S.of(context).delete,
                                                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                                                color: Colors.red,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                    child: Center(
                                                                      child: Container(
                                                                          height: 18,
                                                                          width: 18,
                                                                          alignment: Alignment.centerRight,
                                                                          child: const Icon(
                                                                            Icons.more_vert_sharp,
                                                                            size: 18,
                                                                          )),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ]);
                                                      })),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${lang.S.of(context).showing} ${((_currentPage - 1) * _expensePerPage + 1).toString()} to ${((_currentPage - 1) * _expensePerPage + _expensePerPage).clamp(0, showExpense.length)} of ${showExpense.length} entries',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                InkWell(
                                                  overlayColor: WidgetStateProperty.all<Color>(Colors.grey),
                                                  hoverColor: Colors.grey,
                                                  onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomLeft: Radius.circular(4.0),
                                                        topLeft: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(lang.S.of(context).previous),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: kMainColor,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$_currentPage',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  width: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: kBorderColorTextField),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$pages',
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  hoverColor: Colors.blue.withValues(alpha: 0.1),
                                                  overlayColor: WidgetStateProperty.all<Color>(Colors.blue),
                                                  onTap: _currentPage * _expensePerPage < showExpense.length ? () => setState(() => _currentPage++) : null,
                                                  child: Container(
                                                    height: 32,
                                                    width: 90,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: kBorderColorTextField),
                                                      borderRadius: const BorderRadius.only(
                                                        bottomRight: Radius.circular(4.0),
                                                        topRight: Radius.circular(4.0),
                                                      ),
                                                    ),
                                                    child: const Center(child: Text('Next')),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                //: const EmptyWidget(title: 'No Expense Found'),
                                : EmptyWidget(title: lang.S.of(context).noExpenseFound),
                          ],
                        ),
                      ),
                      // Visibility(visible: MediaQuery.of(context).size.height != 0, child: const Footer()),
                    ],
                  ),
                ));
            // return ExpensesTableWidget(expenses: allExpenses);
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
      ),
    );
  }
}
      
    
  

