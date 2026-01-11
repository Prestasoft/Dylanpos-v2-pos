import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/repo/salary_repo.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/provider/salary_provider.dart';
import 'package:salespro_admin/generated/l10n.dart' as lang;

import '../../../const.dart';
import '../../Widgets/Constant Data/constant.dart';

/// Pantalla mejorada de nómina con cálculos de TSS para República Dominicana
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({
    super.key,
    required this.employee,
    this.existingPayroll,
    required this.ref,
  });

  final EmployeeModel employee;
  final PaySalaryModel? existingPayroll;
  final WidgetRef ref;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  // Controladores
  final TextEditingController overtimeController = TextEditingController(text: '0');
  final TextEditingController bonusController = TextEditingController(text: '0');
  final TextEditingController commissionsController = TextEditingController(text: '0');
  final TextEditingController otherIncomeController = TextEditingController(text: '0');
  final TextEditingController loanDeductionController = TextEditingController(text: '0');
  final TextEditingController advanceController = TextEditingController(text: '0');
  final TextEditingController otherDeductionsController = TextEditingController(text: '0');
  final TextEditingController notesController = TextEditingController();

  // Período
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  int? selectedFortnight;
  DateTime payingDate = DateTime.now();

  // Resultados del cálculo
  PayrollDeductions? deductions;

  final List<String> monthList = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];

  final List<String> monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    checkCurrentUserAndRestartApp();
    _calculateDeductions();

    if (widget.existingPayroll != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final payroll = widget.existingPayroll!;
    overtimeController.text = payroll.overtime.toString();
    bonusController.text = payroll.bonuses.toString();
    commissionsController.text = payroll.commissions.toString();
    otherIncomeController.text = payroll.otherIncome.toString();
    loanDeductionController.text = payroll.loanDeduction.toString();
    advanceController.text = payroll.advanceDeduction.toString();
    otherDeductionsController.text = payroll.otherDeductions.toString();
    notesController.text = payroll.note ?? '';
    selectedYear = payroll.year;
    selectedMonth = payroll.month;
    selectedFortnight = payroll.fortnight;
    payingDate = payroll.payingDate;
    _calculateDeductions();
  }

  void _calculateDeductions() {
    final grossSalary = selectedFortnight != null
        ? widget.employee.salary / 2
        : widget.employee.salary;

    setState(() {
      deductions = PayrollCalculatorRD.calculateDeductions(
        grossSalary: grossSalary,
        overtime: double.tryParse(overtimeController.text) ?? 0,
        bonuses: double.tryParse(bonusController.text) ?? 0,
        commissions: double.tryParse(commissionsController.text) ?? 0,
        otherIncome: double.tryParse(otherIncomeController.text) ?? 0,
        loanDeduction: double.tryParse(loanDeductionController.text) ?? 0,
        advanceDeduction: double.tryParse(advanceController.text) ?? 0,
        otherDeductions: double.tryParse(otherDeductionsController.text) ?? 0,
      );
    });
  }

  @override
  void dispose() {
    overtimeController.dispose();
    bonusController.dispose();
    commissionsController.dispose();
    otherIncomeController.dispose();
    loanDeductionController.dispose();
    advanceController.dispose();
    otherDeductionsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employee = widget.employee;

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: kWhite,
        ),
        width: 900,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(theme, employee),
              const Divider(height: 1, color: kNeutral300),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del empleado
                      _buildEmployeeInfo(theme, employee),
                      const SizedBox(height: 20),

                      // Período de pago
                      _buildPeriodSection(theme),
                      const SizedBox(height: 20),

                      // Ingresos adicionales
                      _buildIncomeSection(theme),
                      const SizedBox(height: 20),

                      // Deducciones adicionales
                      _buildDeductionsSection(theme),
                      const SizedBox(height: 20),

                      // Resumen de cálculos
                      if (deductions != null) _buildCalculationSummary(theme),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: kNeutral300),

              // Botones
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, EmployeeModel employee) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingPayroll != null ? 'Editar Nómina' : 'Generar Nómina',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: kMainColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => GoRouter.of(context).pop(),
            icon: const Icon(FeatherIcons.x, color: kTitleColor, size: 22.0),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo(ThemeData theme, EmployeeModel employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kMainColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMainColor.withAlpha(50)),
      ),
      child: ResponsiveGridRow(
        children: [
          ResponsiveGridCol(
            md: 3,
            xs: 6,
            child: _buildInfoItem('Cédula', employee.cedula),
          ),
          ResponsiveGridCol(
            md: 3,
            xs: 6,
            child: _buildInfoItem('Cargo', employee.designation),
          ),
          ResponsiveGridCol(
            md: 3,
            xs: 6,
            child: _buildInfoItem('Departamento', employee.department),
          ),
          ResponsiveGridCol(
            md: 3,
            xs: 6,
            child: _buildInfoItem('Salario Base', currencyFormat.format(employee.salary)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kNeutral500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Período de Pago',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ResponsiveGridRow(
          children: [
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Año'),
                  value: selectedYear,
                  items: List.generate(5, (i) => (DateTime.now().year - 2 + i).toString())
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedYear = value!),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Mes'),
                  value: selectedMonth,
                  items: monthList.asMap().entries.map((e) =>
                    DropdownMenuItem(value: e.value, child: Text(monthNames[e.key]))
                  ).toList(),
                  onChanged: (value) => setState(() => selectedMonth = value!),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Quincena'),
                  value: selectedFortnight,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Mensual')),
                    DropdownMenuItem(value: 1, child: Text('1ra Quincena')),
                    DropdownMenuItem(value: 2, child: Text('2da Quincena')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedFortnight = value);
                    _calculateDeductions();
                  },
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: payingDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => payingDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha de Pago'),
                    child: Text(DateFormat('dd/MM/yyyy').format(payingDate)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingresos Adicionales',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ResponsiveGridRow(
          children: [
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: overtimeController,
                  label: 'Horas Extras',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: bonusController,
                  label: 'Bonificaciones',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: commissionsController,
                  label: 'Comisiones',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 3,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: otherIncomeController,
                  label: 'Otros Ingresos',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeductionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deducciones Adicionales',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ResponsiveGridRow(
          children: [
            ResponsiveGridCol(
              md: 4,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: loanDeductionController,
                  label: 'Préstamos',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 4,
              xs: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: advanceController,
                  label: 'Adelantos',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
            ResponsiveGridCol(
              md: 4,
              xs: 12,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildAmountField(
                  controller: otherDeductionsController,
                  label: 'Otras Deducciones',
                  onChanged: (_) => _calculateDeductions(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas',
            hintText: 'Observaciones adicionales...',
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'RD\$ ',
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCalculationSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kNeutral100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de Nómina',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ResponsiveGridRow(
            children: [
              // Ingresos
              ResponsiveGridCol(
                md: 4,
                xs: 12,
                child: _buildSummarySection(
                  'Ingresos',
                  Colors.green,
                  [
                    _SummaryItem('Salario Base', selectedFortnight != null
                        ? widget.employee.salary / 2
                        : widget.employee.salary),
                    _SummaryItem('Horas Extras', double.tryParse(overtimeController.text) ?? 0),
                    _SummaryItem('Bonificaciones', double.tryParse(bonusController.text) ?? 0),
                    _SummaryItem('Comisiones', double.tryParse(commissionsController.text) ?? 0),
                    _SummaryItem('Otros', double.tryParse(otherIncomeController.text) ?? 0),
                  ],
                  deductions!.totalIncome,
                ),
              ),

              // Deducciones TSS
              ResponsiveGridCol(
                md: 4,
                xs: 12,
                child: _buildSummarySection(
                  'Deducciones TSS',
                  Colors.orange,
                  [
                    _SummaryItem('AFP (2.87%)', deductions!.afpEmployee),
                    _SummaryItem('SFS (3.04%)', deductions!.sfsEmployee),
                    _SummaryItem('ISR', deductions!.isrWithholding),
                    _SummaryItem('Préstamos', deductions!.loanDeduction),
                    _SummaryItem('Adelantos', deductions!.advanceDeduction),
                    _SummaryItem('Otras', deductions!.otherDeductions),
                  ],
                  deductions!.totalDeductions,
                ),
              ),

              // Aportes Patronales
              ResponsiveGridCol(
                md: 4,
                xs: 12,
                child: _buildSummarySection(
                  'Aportes Patronales',
                  Colors.blue,
                  [
                    _SummaryItem('AFP (7.10%)', deductions!.afpEmployer),
                    _SummaryItem('SFS (7.09%)', deductions!.sfsEmployer),
                    _SummaryItem('SRL (1.10%)', deductions!.srlEmployer),
                    _SummaryItem('INFOTEP (1%)', deductions!.infotep),
                  ],
                  deductions!.totalEmployerCost - deductions!.totalIncome,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SALARIO NETO', style: TextStyle(fontSize: 12, color: kNeutral500)),
                  Text(
                    currencyFormat.format(deductions!.netSalary),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: kGreenTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('COSTO TOTAL EMPLEADOR', style: TextStyle(fontSize: 12, color: kNeutral500)),
                  Text(
                    currencyFormat.format(deductions!.totalEmployerCost),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, Color color, List<_SummaryItem> items, double total) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...items.where((item) => item.value > 0).map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.label, style: const TextStyle(fontSize: 12)),
                Text(currencyFormat.format(item.value), style: const TextStyle(fontSize: 12)),
              ],
            ),
          )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(currencyFormat.format(total), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => GoRouter.of(context).pop(),
              child: Text(lang.S.of(context).cancel),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGreenTextColor),
              onPressed: _savePayroll,
              child: Text(widget.existingPayroll != null
                  ? lang.S.of(context).update
                  : 'Guardar y Pagar'),
            ),
          ),
        ],
      ),
    );
  }

  void _savePayroll() async {
    if (formKey.currentState?.validate() ?? false) {
      if (deductions == null) return;

      final grossSalary = selectedFortnight != null
          ? widget.employee.salary / 2
          : widget.employee.salary;

      final monthNum = int.parse(selectedMonth);
      final yearNum = int.parse(selectedYear);
      DateTime periodStart;
      DateTime periodEnd;

      if (selectedFortnight != null) {
        if (selectedFortnight == 1) {
          periodStart = DateTime(yearNum, monthNum, 1);
          periodEnd = DateTime(yearNum, monthNum, 15);
        } else {
          periodStart = DateTime(yearNum, monthNum, 16);
          periodEnd = DateTime(yearNum, monthNum + 1, 0);
        }
      } else {
        periodStart = DateTime(yearNum, monthNum, 1);
        periodEnd = DateTime(yearNum, monthNum + 1, 0);
      }

      final payroll = PaySalaryModel(
        id: widget.existingPayroll?.id ?? DateTime.now().millisecondsSinceEpoch,
        employeeName: widget.employee.fullName,
        employeeCedula: widget.employee.cedula,
        employeeId: widget.employee.id,
        designationId: widget.employee.designationId,
        designation: widget.employee.designation,
        department: widget.employee.department,
        year: selectedYear,
        month: selectedMonth,
        fortnight: selectedFortnight,
        payingDate: payingDate,
        periodStart: periodStart,
        periodEnd: periodEnd,
        grossSalary: grossSalary,
        overtime: double.tryParse(overtimeController.text) ?? 0,
        bonuses: double.tryParse(bonusController.text) ?? 0,
        commissions: double.tryParse(commissionsController.text) ?? 0,
        otherIncome: double.tryParse(otherIncomeController.text) ?? 0,
        totalIncome: deductions!.totalIncome,
        afpEmployee: deductions!.afpEmployee,
        sfsEmployee: deductions!.sfsEmployee,
        totalTSS: deductions!.totalTSS,
        afpEmployer: deductions!.afpEmployer,
        sfsEmployer: deductions!.sfsEmployer,
        srlEmployer: deductions!.srlEmployer,
        infotep: deductions!.infotep,
        taxableIncome: deductions!.taxableIncome,
        isrWithholding: deductions!.isrWithholding,
        loanDeduction: deductions!.loanDeduction,
        advanceDeduction: deductions!.advanceDeduction,
        otherDeductions: deductions!.otherDeductions,
        totalDeductions: deductions!.totalDeductions,
        netSalary: deductions!.netSalary,
        paymentType: widget.employee.paymentMethod,
        status: 'Pagado',
        note: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );

      bool result;
      if (widget.existingPayroll != null) {
        result = await SalaryRepository().updateSalary(salary: payroll);
      } else {
        result = await SalaryRepository().paySalary(salary: payroll);
      }

      if (result) {
        // ignore: unused_result
        widget.ref.refresh(salaryProvider);
        if (mounted) {
          GoRouter.of(context).pop();
        }
      }
    }
  }
}

class _SummaryItem {
  final String label;
  final double value;
  _SummaryItem(this.label, this.value);
}
