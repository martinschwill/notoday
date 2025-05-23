import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

List<charts.Series<SymptomData, String>> buildChartData(
  List<SymptomData> symptomData,
  List<dynamic> slipups,
  String Function(String) formatToDayMonth,
) {
  return [
    charts.Series<SymptomData, String>(
      id: 'Objawy',
      colorFn: (SymptomData symptoms, __) => slipups.contains(symptoms.date)
          ? charts.ColorUtil.fromDartColor(const Color.fromARGB(255, 223, 2, 2))
          : charts.ColorUtil.fromDartColor(Colors.blueGrey),

      labelAccessorFn: (SymptomData symptoms, __) =>
          slipups.contains(symptoms.date) ? 'Z' : '',
      domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
      measureFn: (SymptomData symptoms, _) => symptoms.symptomCount,
      data: symptomData,
    ),
    charts.Series<SymptomData, String>(
      id: 'Emocje -',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
      measureFn: (SymptomData symptoms, _) => symptoms.minusEmoCount,
      data: symptomData,
    )
      ..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxis')
      ..setAttribute(charts.rendererIdKey, 'secondary'),
    charts.Series<SymptomData, String>(
      id: 'Emocje +',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
      measureFn: (SymptomData symptoms, _) => symptoms.plusEmoCount,
      data: symptomData,
    )
      ..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxis')
      ..setAttribute(charts.rendererIdKey, 'secondary'),
  ];
}


List<charts.Series<SymptomData, String>> buildChartData2(
  List<SymptomData> symptomData,
  String Function(String) formatToDayMonth,
) {
  return [
    charts.Series<SymptomData, String>(
            id: 'Emocje -',
            seriesCategory: 'A',
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
            measureFn: (SymptomData symptoms, _) => symptoms.minusEmoCount,
            data: symptomData,
          ),
          // charts.Series<SymptomData, String>(
          //   id: 'Emocje +',
          //   seriesCategory: 'A',
          //   colorFn: (_, __) => charts.MaterialPalette.gray.shadeDefault,
          //   domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
          //   measureFn: (SymptomData symptoms, _) => symptoms.plusEmoCount,
          //   data: symptomData,
          // ),

          charts.Series<SymptomData, String>(
            id: 'Emocje +',
            seriesCategory: 'B',
            colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
            domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
            measureFn: (SymptomData symptoms, _) => symptoms.plusEmoCount,
            data: symptomData,
          ), 
          // charts.Series<SymptomData, String>(
          //   id: 'Emocje -',
          //   seriesCategory: 'B',
          //   colorFn: (_, __) => charts.MaterialPalette.gray.shadeDefault,
          //   domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
          //   measureFn: (SymptomData symptoms, _) => symptoms.minusEmoCount,
          //   data: symptomData,
          // ),
  ];
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