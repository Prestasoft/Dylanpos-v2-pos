import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee_performance_model.dart';

/// Widget de gráfica de tendencias de comisiones
class CommissionTrendsChart extends StatelessWidget {
  final List<EmployeePerformance> performances;
  final String title;
  final Color primaryColor;

  const CommissionTrendsChart({
    super.key,
    required this.performances,
    this.title = 'Tendencia de Comisiones',
    this.primaryColor = Colors.purple,
  });

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay datos para mostrar'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Tomar top 10 empleados
    final topPerformances = performances.take(10).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxCommission(topPerformances) * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < topPerformances.length) {
                final perf = topPerformances[groupIndex];
                return BarTooltipItem(
                  '${perf.employeeName}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(rod.toY),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < topPerformances.length) {
                  final name = topPerformances[index].employeeName;
                  // Tomar solo el primer nombre
                  final firstName = name.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      firstName,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxCommission(topPerformances) * 1.2 / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withAlpha(51),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.withAlpha(128)),
            bottom: BorderSide(color: Colors.grey.withAlpha(128)),
          ),
        ),
        barGroups: topPerformances.asMap().entries.map((entry) {
          final index = entry.key;
          final perf = entry.value;

          // Colores basados en tier
          Color barColor = primaryColor;
          if (perf.assignedTier != null) {
            barColor = Color(perf.assignedTier!.color);
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: perf.commissionEarned,
                color: barColor,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _getMaxCommission(topPerformances) * 1.2,
                  color: Colors.grey.withAlpha(13),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _getMaxCommission(List<EmployeePerformance> perfs) {
    if (perfs.isEmpty) return 10000;
    return perfs.map((p) => p.commissionEarned).reduce((a, b) => a > b ? a : b);
  }
}

/// Widget de gráfica de línea para tendencias de ingresos
class RevenueTrendChart extends StatelessWidget {
  final List<EmployeePerformance> performances;
  final String title;

  const RevenueTrendChart({
    super.key,
    required this.performances,
    this.title = 'Tendencia de Ingresos',
  });

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay datos para mostrar'),
        ),
      );
    }

    final topPerformances = performances.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (topPerformances.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxRevenue(topPerformances) * 1.2,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topPerformances.length) {
                          final name = topPerformances[index].employeeName.split(' ').first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxRevenue(topPerformances) * 1.2 / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(51),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.withAlpha(128)),
                    bottom: BorderSide(color: Colors.grey.withAlpha(128)),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: topPerformances.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.totalRevenue);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withAlpha(25),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < topPerformances.length) {
                          final perf = topPerformances[index];
                          return LineTooltipItem(
                            '${perf.employeeName}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(spot.y),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxRevenue(List<EmployeePerformance> perfs) {
    if (perfs.isEmpty) return 100000;
    return perfs.map((p) => p.totalRevenue).reduce((a, b) => a > b ? a : b);
  }
}
