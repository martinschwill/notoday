import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartDataBuilder {
  static List<BarChartGroupData> buildChartData(
    List<SymptomData> symptomData,
    List<dynamic> slipups,
    String Function(String) formatToDayMonth,
  ) {
    return symptomData.asMap().entries.map((entry) {
      int index = entry.key;
      SymptomData data = entry.value;
      
      bool hasSlipup = slipups.contains(data.date);
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.symptomCount.toDouble(),
            gradient: hasSlipup
            ? LinearGradient(
              colors: [
                const Color.fromARGB(255, 157, 150, 6),
                Color.fromARGB(255, 0, 0, 0)
              ],
            )
            : null, 
            color: Colors.blueGrey,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  static List<LineChartBarData> buildLineData(
    List<SymptomData> symptomData,
    String Function(String) formatToDayMonth,
  ) {
    List<FlSpot> minusEmoSpots = symptomData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.minusEmoCount.toDouble());
    }).toList();

    List<FlSpot> plusEmoSpots = symptomData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.plusEmoCount.toDouble());
    }).toList();

    return [
      LineChartBarData(
        spots: minusEmoSpots,
        isCurved: true,
        color: Colors.red.withOpacity(0.7),
        barWidth: 1,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.red.withOpacity(0.2),
        ),
      ),
      LineChartBarData(
        spots: plusEmoSpots,
        isCurved: true,
        color: Colors.green.withOpacity(0.7),
        barWidth: 1,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withOpacity(0.2),
        ),
      ),
    ];
  }

  static List<BarChartGroupData> buildChartData2(
    List<SymptomData> symptomData,
    String Function(String) formatToDayMonth,
  ) {
    return symptomData.asMap().entries.map((entry) {
      int index = entry.key;
      SymptomData data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.minusEmoCount.toDouble(),
            color: const Color.fromARGB(255, 222, 54, 42),
            width: 4,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: data.plusEmoCount.toDouble(),
            color: const Color.fromARGB(255, 63, 145, 66),
            width: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  static List<String> getBottomTitles(List<SymptomData> symptomData, String Function(String) formatToDayMonth) {
    return symptomData.map((data) => formatToDayMonth(data.date)).toList();
  }
}
class SymptomData {
  final String date;
  final int symptomCount;
  final int plusEmoCount; // Added field
  final int minusEmoCount; // Added field

  SymptomData({
    required this.date,
    required this.symptomCount,
    required this.plusEmoCount, // Added parameter
    required this.minusEmoCount, // Added parameter
  });

  @override
  String toString() {
    return 'SymptomData(date: $date, symptomCount: $symptomCount, plusEmoCount: $plusEmoCount, minusEmoCount: $minusEmoCount)';
  }
}