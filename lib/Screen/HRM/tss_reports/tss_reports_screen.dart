import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/model/pay_salary_model.dart';
import 'package:salespro_admin/Screen/HRM/salaries%20list/repo/salary_repo.dart';

import '../../Widgets/Constant Data/constant.dart';

class TSSReportsScreen extends StatefulWidget {
  const TSSReportsScreen({super.key});

  static const String route = '/hrm/tss-reports';

  @override
  State<TSSReportsScreen> createState() => _TSSReportsScreenState();
}

class _TSSReportsScreenState extends State<TSSReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  PayrollSummary? summary;
  List<PaySalaryModel> payrollList = [];
  bool isLoading = true;

  final SalaryRepository _salaryRepo = SalaryRepository();
  final currencyFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$');

  final List<String> months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];

  final Map<String, String> monthNames = {
    '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
    '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
    '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final summaryData = await _salaryRepo.getPayrollSummary(selectedYear, selectedMonth);
      final payroll = await _salaryRepo.getSalariesByPeriod(selectedYear, selectedMonth);

      setState(() {
        summary = summaryData;
        payrollList = payroll;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      toast('Error al cargar datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMainColor.withValues(alpha: 0.02),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTSSReportTab(),
                          _buildAFPReportTab(),
                          _buildSFSReportTab(),
                          _buildISRReportTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: kMainColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reportes TSS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Tesorería de la Seguridad Social - República Dominicana',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Selector de período
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: kMainColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonth,
                items: months.map((m) {
                  return DropdownMenuItem(value: m, child: Text(monthNames[m]!));
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedMonth = value!);
                  _loadData();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: kMainColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                items: List.generate(5, (index) {
                  final year = (DateTime.now().year - 2 + index).toString();
                  return DropdownMenuItem(value: year, child: Text(year));
                }),
                onChanged: (value) {
                  setState(() => selectedYear = value!);
                  _loadData();
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _exportReport(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: kMainColor),
            tooltip: 'Refrescar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: kMainColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: kMainColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Resumen TSS'),
          Tab(text: 'Reporte AFP'),
          Tab(text: 'Reporte SFS'),
          Tab(text: 'Reporte ISR (IR-17)'),
        ],
      ),
    );
  }

  Widget _buildTSSReportTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (summary == null || summary!.employeeCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos de nómina para ${monthNames[selectedMonth]} $selectedYear',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del período
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kMainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: kMainColor),
                const SizedBox(width: 12),
                Text(
                  'Período: ${monthNames[selectedMonth]} $selectedYear',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary!.employeeCount} empleados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cards de resumen
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryCard(
                'Salario Bruto Total',
                currencyFormat.format(summary!.totalGrossSalary),
                Icons.attach_money,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Salario Neto Total',
                currencyFormat.format(summary!.totalNetSalary),
                Icons.payments,
                Colors.green,
              ),
              _buildSummaryCard(
                'Total TSS Empleado',
                currencyFormat.format(summary!.totalTSSEmployee),
                Icons.person,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Total TSS Patronal',
                currencyFormat.format(summary!.totalEmployerContributions),
                Icons.business,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabla de detalle TSS
          const Text(
            'Desglose de Aportes TSS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey[200]!),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Concepto',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Tasa',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Empleado',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Empleador',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _buildTSSRow(
                    'AFP (Fondo de Pensiones)', '2.87% / 7.10%',
                    summary!.totalAFPEmployee, summary!.totalAFPEmployer),
                _buildTSSRow(
                    'SFS (Seguro Familiar de Salud)', '3.04% / 7.09%',
                    summary!.totalSFSEmployee, summary!.totalSFSEmployer),
                _buildTSSRow('SRL (Riesgos Laborales)', '- / 1.00-1.40%',
                    0, summary!.totalSRL),
                _buildTSSRow(
                    'INFOTEP', '- / 1.00%', 0, summary!.totalINFOTEP),
                TableRow(
                  decoration: BoxDecoration(color: Colors.green[50]),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        currencyFormat.format(summary!.totalTSSEmployee),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        currencyFormat.format(summary!.totalEmployerContributions),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Totales a pagar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL A PAGAR A TSS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currencyFormat.format(summary!.totalTSSPayment),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '(Aportes empleado + patronal)',
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL ISR A PAGAR (IR-17)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currencyFormat.format(summary!.totalISR),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTSSRow(String concept, String rate, double employee, double employer) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(concept),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(rate),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(currencyFormat.format(employee)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(currencyFormat.format(employer)),
        ),
      ],
    );
  }

  Widget _buildAFPReportTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(
            'Reporte de Aportes AFP',
            'Fondo de Pensiones - ${monthNames[selectedMonth]} $selectedYear',
            Colors.blue,
          ),
          const SizedBox(height: 20),

          // Información de tasas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasas AFP vigentes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Empleado: 2.87% | Empleador: 7.10%'),
                    Text('Tope cotizable: RD\$472,950.00'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Resumen
          Row(
            children: [
              Expanded(
                child: _buildMiniCard('Total Empleados',
                    currencyFormat.format(summary?.totalAFPEmployee ?? 0), Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniCard('Total Patronal',
                    currencyFormat.format(summary?.totalAFPEmployer ?? 0), Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniCard(
                    'Total AFP',
                    currencyFormat.format(
                        (summary?.totalAFPEmployee ?? 0) + (summary?.totalAFPEmployer ?? 0)),
                    Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabla de detalle por empleado
          const Text(
            'Detalle por Empleado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildEmployeeTable(['Empleado', 'Cédula', 'Salario', 'AFP Empleado', 'AFP Patronal', 'Total'],
              payrollList.map((p) => [
                p.employeeName,
                p.employeeCedula,
                currencyFormat.format(p.grossSalary),
                currencyFormat.format(p.afpEmployee),
                currencyFormat.format(p.afpEmployer),
                currencyFormat.format(p.afpEmployee + p.afpEmployer),
              ]).toList()),
        ],
      ),
    );
  }

  Widget _buildSFSReportTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(
            'Reporte de Aportes SFS',
            'Seguro Familiar de Salud - ${monthNames[selectedMonth]} $selectedYear',
            Colors.green,
          ),
          const SizedBox(height: 20),

          // Información de tasas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Tasas SFS vigentes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Empleado: 3.04% | Empleador: 7.09%'),
                const Text('SRL (Riesgos Laborales): 1.00% - 1.40% empleador'),
                Text('Tope cotizable: ${currencyFormat.format(472950)}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Resumen
          Row(
            children: [
              Expanded(
                child: _buildMiniCard('SFS Empleados',
                    currencyFormat.format(summary?.totalSFSEmployee ?? 0), Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniCard('SFS Patronal',
                    currencyFormat.format(summary?.totalSFSEmployer ?? 0), Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniCard(
                    'SRL Patronal', currencyFormat.format(summary?.totalSRL ?? 0), Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tabla de detalle por empleado
          const Text(
            'Detalle por Empleado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildEmployeeTable(
              ['Empleado', 'Cédula', 'Salario', 'SFS Empleado', 'SFS Patronal', 'SRL'],
              payrollList.map((p) => [
                p.employeeName,
                p.employeeCedula,
                currencyFormat.format(p.grossSalary),
                currencyFormat.format(p.sfsEmployee),
                currencyFormat.format(p.sfsEmployer),
                currencyFormat.format(p.srlEmployer),
              ]).toList()),
        ],
      ),
    );
  }

  Widget _buildISRReportTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(
            'Reporte ISR (IR-17)',
            'Impuesto Sobre la Renta - ${monthNames[selectedMonth]} $selectedYear',
            Colors.red,
          ),
          const SizedBox(height: 20),

          // Información de tasas ISR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Tabla de ISR 2024 (Mensual):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Table(
                  border: TableBorder.all(color: Colors.red.shade200),
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0xFFFFCDD2)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Renta Mensual', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Tasa', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Hasta RD\$34,685')),
                      Padding(padding: EdgeInsets.all(8), child: Text('Exento')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('RD\$34,685 - RD\$52,027')),
                      Padding(padding: EdgeInsets.all(8), child: Text('15%')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('RD\$52,027 - RD\$72,260')),
                      Padding(padding: EdgeInsets.all(8), child: Text('20%')),
                    ]),
                    TableRow(children: [
                      Padding(padding: EdgeInsets.all(8), child: Text('Más de RD\$72,260')),
                      Padding(padding: EdgeInsets.all(8), child: Text('25%')),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Resumen ISR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text(
                      'Total ISR a Retener',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      currencyFormat.format(summary?.totalISR ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabla de detalle por empleado
          const Text(
            'Detalle de Retenciones ISR por Empleado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildEmployeeTable(
              ['Empleado', 'Ingreso Bruto', 'TSS Empleado', 'Base Imponible', 'ISR Retenido'],
              payrollList.map((p) => [
                p.employeeName,
                currencyFormat.format(p.totalIncome),
                currencyFormat.format(p.totalTSS),
                currencyFormat.format(p.taxableIncome),
                currencyFormat.format(p.isrWithholding),
              ]).toList()),
        ],
      ),
    );
  }

  Widget _buildReportHeader(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: color, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: color.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _exportReport(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(List<String> headers, List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
          rows: rows.map((row) {
            return DataRow(
              cells: row.map((cell) => DataCell(Text(cell))).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportReport() {
    toast('Función de exportación en desarrollo');
  }
}
