import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/finance_provider.dart';
import '../core/widgets/glass_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSpendChart(context),
              const SizedBox(height: 24),
              _buildBreakdown(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendChart(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        // Prepare data for the last 7 days
        final List<double> last7Days = List.filled(7, 0.0);
        final today = DateTime.now();
        final weekDays = List.generate(7, (index) {
          final date = today.subtract(Duration(days: 6 - index));
          return DateFormat('E').format(date);
        });

        for (var t in provider.transactions) {
          if (t.isExpense) {
            final diff = today.difference(t.date).inDays;
            if (diff >= 0 && diff < 7) {
              last7Days[6 - diff] += t.amount;
            }
          }
        }

        final maxVal = last7Days.reduce(
          (curr, next) => curr > next ? curr : next,
        );
        final maxY = maxVal == 0 ? 100.0 : maxVal * 1.2;

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Spending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          // tooltipBgColor: AppColors.glassWhite,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              weekDays[group.x.toInt()],
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: '\n${rod.toY.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: AppColors.accentGreen,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  weekDays[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: last7Days[index],
                              color: AppColors.accentGreen,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ],
                        );
                      }),
                      gridData: FlGridData(show: false),
                      maxY: maxY,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreakdown(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        // Group expenses by category
        final Map<String, double> categories = {};
        for (var t in provider.transactions) {
          if (t.isExpense) {
            categories[t.category] = (categories[t.category] ?? 0) + t.amount;
          }
        }

        if (categories.isEmpty) {
          return GlassCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: const Text(
                "No expenses recorded yet for breakdown.",
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final sortedKeys = categories.keys.toList()
          ..sort((a, b) => categories[b]!.compareTo(categories[a]!));

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending by Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(sortedKeys.length, (i) {
                        final isTouched = i == _touchedIndex;
                        final fontSize = isTouched ? 25.0 : 16.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        final key = sortedKeys[i];
                        final value = categories[key]!;
                        // Simple color generation
                        final color =
                            Colors.primaries[i % Colors.primaries.length];

                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title:
                              '${(value / categories.values.fold(0.0, (s, v) => s + v) * 100).toInt()}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 2),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Legend
                Column(
                  children: List.generate(sortedKeys.length, (i) {
                    final key = sortedKeys[i];
                    final value = categories[key]!;
                    final color = Colors.primaries[i % Colors.primaries.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                key,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          Text(
                            NumberFormat.simpleCurrency(
                              name: 'PKR',
                            ).format(value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
