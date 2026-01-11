import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/employees/model/employee_model.dart';
import 'package:salespro_admin/Screen/HRM/employees/repo/employee_repo.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/repo/salary_repo.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/provider/salary_provider.dart';

import '../../Widgets/Constant Data/constant.dart';

/// Pantalla completa de Nómina con cálculo detallado RD
class NominaCompletaScreen extends StatefulWidget {
  const NominaCompletaScreen({super.key, this.payedSalary, required this.ref});

  final PaySalaryModel? payedSalary;
  final WidgetRef ref;

  @override
  State<NominaCompletaScreen> createState() => _NominaCompletaScreenState();
}

class _NominaCompletaScreenState extends State<NominaCompletaScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController salarioBrutoController = TextEditingController();
  final TextEditingController horasExtrasController = TextEditingController(text: '0');
  final TextEditingController bonificacionesController = TextEditingController(text: '0');
  final TextEditingController comisionesController = TextEditingController(text: '0');
  final TextEditingController otrosIngresosController = TextEditingController(text: '0');
  final TextEditingController prestamosController = TextEditingController(text: '0');
  final TextEditingController adelantosController = TextEditingController(text: '0');
  final TextEditingController otrasDeduccionesController = TextEditingController(text: '0');
  final TextEditingController notasController = TextEditingController();

  // Selecciones
  List<EmployeeModel> employees = [];
  EmployeeModel? selectedEmployee;
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  int? selectedFortnight; // null = mensual, 1 = primera quincena, 2 = segunda quincena
  String selectedPaymentType = 'Transferencia';
  bool isLoading = true;

  // Resultados del cálculo
  PayrollDeductions? deductions;

  final List<String> paymentTypes = ['Transferencia', 'Cheque', 'Efectivo'];
  final List<String> years = List.generate(10, (i) => (DateTime.now().year - 5 + i).toString());
  final Map<String, String> months = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre',
  };

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _setupListeners();
  }

  void _setupListeners() {
    salarioBrutoController.addListener(_recalculate);
    horasExtrasController.addListener(_recalculate);
    bonificacionesController.addListener(_recalculate);
    comisionesController.addListener(_recalculate);
    otrosIngresosController.addListener(_recalculate);
    prestamosController.addListener(_recalculate);
    adelantosController.addListener(_recalculate);
    otrasDeduccionesController.addListener(_recalculate);
  }

  Future<void> _loadEmployees() async {
    try {
      final empList = await EmployeeRepository().getAllEmployees();
      setState(() {
        employees = empList;
        isLoading = false;
      });

      // Si estamos editando, cargar los datos
      if (widget.payedSalary != null) {
        _loadExistingData();
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _loadExistingData() {
    final salary = widget.payedSalary!;
    salarioBrutoController.text = salary.grossSalary.toString();
    horasExtrasController.text = salary.overtime.toString();
    bonificacionesController.text = salary.bonuses.toString();
    comisionesController.text = salary.commissions.toString();
    otrosIngresosController.text = salary.otherIncome.toString();
    prestamosController.text = salary.loanDeduction.toString();
    adelantosController.text = salary.advanceDeduction.toString();
    otrasDeduccionesController.text = salary.otherDeductions.toString();
    notasController.text = salary.note ?? '';
    selectedYear = salary.year;
    selectedMonth = salary.month;
    selectedFortnight = salary.fortnight;
    selectedPaymentType = salary.paymentType;

    // Buscar empleado
    for (var emp in employees) {
      if (emp.id == salary.employeeId) {
        setState(() => selectedEmployee = emp);
        break;
      }
    }
    _recalculate();
  }

  void _recalculate() {
    final grossSalary = double.tryParse(salarioBrutoController.text) ?? 0;
    final overtime = double.tryParse(horasExtrasController.text) ?? 0;
    final bonuses = double.tryParse(bonificacionesController.text) ?? 0;
    final commissions = double.tryParse(comisionesController.text) ?? 0;
    final otherIncome = double.tryParse(otrosIngresosController.text) ?? 0;
    final loanDeduction = double.tryParse(prestamosController.text) ?? 0;
    final advanceDeduction = double.tryParse(adelantosController.text) ?? 0;
    final otherDeductions = double.tryParse(otrasDeduccionesController.text) ?? 0;

    setState(() {
      deductions = PayrollCalculatorRD.calculateDeductions(
        grossSalary: grossSalary,
        overtime: overtime,
        bonuses: bonuses,
        commissions: commissions,
        otherIncome: otherIncome,
        loanDeduction: loanDeduction,
        advanceDeduction: advanceDeduction,
        otherDeductions: otherDeductions,
      );
    });
  }

  void _onEmployeeSelected(EmployeeModel? employee) {
    setState(() {
      selectedEmployee = employee;
      if (employee != null) {
        // Auto-llenar salario base del empleado
        double baseSalary = employee.salary;
        if (selectedFortnight != null) {
          baseSalary = employee.salary / 2; // Quincena
        }
        salarioBrutoController.text = baseSalary.toStringAsFixed(2);
      }
    });
  }

  void _onFortnightChanged(int? value) {
    setState(() {
      selectedFortnight = value;
      if (selectedEmployee != null) {
        double baseSalary = selectedEmployee!.salary;
        if (value != null) {
          baseSalary = selectedEmployee!.salary / 2;
        }
        salarioBrutoController.text = baseSalary.toStringAsFixed(2);
      }
    });
  }

  Future<void> _saveSalary() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedEmployee == null) {
      toast('Seleccione un empleado');
      return;
    }
    if (deductions == null) {
      toast('Error en el cálculo');
      return;
    }

    final now = DateTime.now();
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

    final salary = PaySalaryModel(
      id: widget.payedSalary != null ? widget.payedSalary!.id : DateTime.now().millisecondsSinceEpoch,
      employeeName: selectedEmployee!.name,
      employeeCedula: selectedEmployee!.cedula,
      employeeId: selectedEmployee!.id,
      designationId: selectedEmployee!.designationId,
      designation: selectedEmployee!.designation,
      department: selectedEmployee!.department ?? 'General',
      year: selectedYear,
      month: selectedMonth,
      fortnight: selectedFortnight,
      payingDate: now,
      periodStart: periodStart,
      periodEnd: periodEnd,
      grossSalary: double.tryParse(salarioBrutoController.text) ?? 0,
      overtime: double.tryParse(horasExtrasController.text) ?? 0,
      bonuses: double.tryParse(bonificacionesController.text) ?? 0,
      commissions: double.tryParse(comisionesController.text) ?? 0,
      otherIncome: double.tryParse(otrosIngresosController.text) ?? 0,
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
      loanDeduction: double.tryParse(prestamosController.text) ?? 0,
      advanceDeduction: double.tryParse(adelantosController.text) ?? 0,
      otherDeductions: double.tryParse(otrasDeduccionesController.text) ?? 0,
      totalDeductions: deductions!.totalDeductions,
      netSalary: deductions!.netSalary,
      paymentType: selectedPaymentType,
      status: 'Pagado',
      note: notasController.text.isEmpty ? null : notasController.text,
    );

    bool result;
    if (widget.payedSalary != null) {
      result = await SalaryRepository().updateSalary(salary: salary);
    } else {
      result = await SalaryRepository().paySalary(salary: salary);
    }

    if (result) {
      // ignore: unused_result
      widget.ref.refresh(salaryProvider);
      if (mounted) {
        GoRouter.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    salarioBrutoController.dispose();
    horasExtrasController.dispose();
    bonificacionesController.dispose();
    comisionesController.dispose();
    otrosIngresosController.dispose();
    prestamosController.dispose();
    adelantosController.dispose();
    otrasDeduccionesController.dispose();
    notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kMainColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    widget.payedSalary != null ? 'Editar Pago de Nómina' : 'Nuevo Pago de Nómina',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna izquierda - Formulario
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Información del Empleado'),
                            const SizedBox(height: 12),
                            _buildEmployeeSelector(),
                            const SizedBox(height: 16),
                            _buildPeriodSelector(),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Ingresos'),
                            const SizedBox(height: 12),
                            _buildIncomeFields(),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Deducciones Adicionales'),
                            const SizedBox(height: 12),
                            _buildDeductionFields(),
                            const SizedBox(height: 24),

                            _buildSectionTitle('Método de Pago'),
                            const SizedBox(height: 12),
                            _buildPaymentMethod(),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Columna derecha - Resumen de cálculos
                      Expanded(
                        flex: 2,
                        child: _buildCalculationSummary(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveSalary,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Nómina'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: kTitleColor,
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return DropdownButtonFormField<EmployeeModel>(
      initialValue: selectedEmployee,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Seleccionar Empleado *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items: employees.map((emp) {
        return DropdownMenuItem(
          value: emp,
          child: Text('${emp.name} - ${emp.designation}'),
        );
      }).toList(),
      onChanged: _onEmployeeSelected,
      validator: (value) => value == null ? 'Seleccione un empleado' : null,
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedYear,
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
            ),
            items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
            onChanged: (v) => setState(() => selectedYear = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Mes',
              border: OutlineInputBorder(),
            ),
            items: months.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => selectedMonth = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int?>(
            initialValue: selectedFortnight,
            decoration: const InputDecoration(
              labelText: 'Período',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Mensual')),
              DropdownMenuItem(value: 1, child: Text('1ra Quincena')),
              DropdownMenuItem(value: 2, child: Text('2da Quincena')),
            ],
            onChanged: _onFortnightChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: salarioBrutoController,
                decoration: const InputDecoration(
                  labelText: 'Salario Bruto *',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: horasExtrasController,
                decoration: const InputDecoration(
                  labelText: 'Horas Extras',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: bonificacionesController,
                decoration: const InputDecoration(
                  labelText: 'Bonificaciones',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: comisionesController,
                decoration: const InputDecoration(
                  labelText: 'Comisiones',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: otrosIngresosController,
                decoration: const InputDecoration(
                  labelText: 'Otros Ingresos',
                  border: OutlineInputBorder(),
                  prefixText: 'RD\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeductionFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: prestamosController,
            decoration: const InputDecoration(
              labelText: 'Préstamos',
              border: OutlineInputBorder(),
              prefixText: 'RD\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: adelantosController,
            decoration: const InputDecoration(
              labelText: 'Adelantos',
              border: OutlineInputBorder(),
              prefixText: 'RD\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: otrasDeduccionesController,
            decoration: const InputDecoration(
              labelText: 'Otras Deducciones',
              border: OutlineInputBorder(),
              prefixText: 'RD\$ ',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selectedPaymentType,
            decoration: const InputDecoration(
              labelText: 'Método de Pago',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            items: paymentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => selectedPaymentType = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: notasController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Cálculo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTitleColor,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),

          // Ingresos
          _buildSummarySection(
            'INGRESOS',
            Colors.green.shade700,
            [
              _buildSummaryRow('Salario Bruto', deductions?.totalIncome ?? 0 - (deductions?.totalIncome ?? 0)),
              _buildSummaryRow('(+) Otros Ingresos',
                (double.tryParse(horasExtrasController.text) ?? 0) +
                (double.tryParse(bonificacionesController.text) ?? 0) +
                (double.tryParse(comisionesController.text) ?? 0) +
                (double.tryParse(otrosIngresosController.text) ?? 0)),
              _buildSummaryRow('Total Ingresos', deductions?.totalIncome ?? 0, isBold: true),
            ],
          ),

          const SizedBox(height: 16),

          // Deducciones TSS
          _buildSummarySection(
            'DEDUCCIONES TSS (Empleado)',
            Colors.blue.shade700,
            [
              _buildSummaryRow('AFP (2.87%)', deductions?.afpEmployee ?? 0),
              _buildSummaryRow('SFS (3.04%)', deductions?.sfsEmployee ?? 0),
              _buildSummaryRow('Total TSS', deductions?.totalTSS ?? 0, isBold: true),
            ],
          ),

          const SizedBox(height: 16),

          // ISR
          _buildSummarySection(
            'IMPUESTO SOBRE LA RENTA',
            Colors.orange.shade700,
            [
              _buildSummaryRow('Ingreso Gravable', deductions?.taxableIncome ?? 0),
              _buildSummaryRow('Retención ISR', deductions?.isrWithholding ?? 0, isBold: true),
            ],
          ),

          const SizedBox(height: 16),

          // Otras deducciones
          _buildSummarySection(
            'OTRAS DEDUCCIONES',
            Colors.red.shade700,
            [
              _buildSummaryRow('Préstamos', double.tryParse(prestamosController.text) ?? 0),
              _buildSummaryRow('Adelantos', double.tryParse(adelantosController.text) ?? 0),
              _buildSummaryRow('Otras', double.tryParse(otrasDeduccionesController.text) ?? 0),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 2),

          // Total deducciones
          _buildSummaryRow('TOTAL DEDUCCIONES', deductions?.totalDeductions ?? 0,
            isBold: true, color: Colors.red),

          const SizedBox(height: 12),

          // Salario Neto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kMainColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SALARIO NETO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),
                ),
                Text(
                  currencyFormat.format(deductions?.netSalary ?? 0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Aportes patronales (informativo)
          ExpansionTile(
            title: const Text(
              'Aportes Patronales (Info)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(left: 8),
            children: [
              _buildSummaryRow('AFP Patronal (7.10%)', deductions?.afpEmployer ?? 0, fontSize: 12),
              _buildSummaryRow('SFS Patronal (7.09%)', deductions?.sfsEmployer ?? 0, fontSize: 12),
              _buildSummaryRow('SRL (1.10%)', deductions?.srlEmployer ?? 0, fontSize: 12),
              _buildSummaryRow('INFOTEP (1%)', deductions?.infotep ?? 0, fontSize: 12),
              const Divider(),
              _buildSummaryRow('Costo Total Empleador', deductions?.totalEmployerCost ?? 0,
                isBold: true, fontSize: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {
    bool isBold = false,
    Color? color,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
