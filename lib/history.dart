import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class HistoryPage extends StatefulWidget {
  final int userId;

  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<charts.Series<SymptomData, String>> _chartData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserSymptoms();
  }

  Future<void> _fetchUserSymptoms() async {
  try {
    final payload = json.encode({
      "user_id": widget.userId,
      "days": 30,
    });
    final response = await http.post(
      Uri.parse('$baseUrl/days/past'),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isEmpty) {
        setState(() {
          _chartData = [];
          _isLoading = false;
        });
        return;
      }

      final List<SymptomData> symptomData = data.map((item) {
        final List<dynamic> emotions = (item['emotions'] ?? []) as List<dynamic>;
        final List<dynamic> symptoms = (item['symptoms'] ?? []) as List<dynamic>;

        final List<dynamic> plusEmotions = emotions
            .where((emotion) => emotion['sign'] == 'plus')
            .toList();

        final List<dynamic> minusEmotions = emotions
            .where((emotion) => emotion['sign'] == 'minus')
            .toList();

        return SymptomData(
          date: item['date'] ?? 'Unknown',
          symptomCount: symptoms.length,
          plusEmoCount: plusEmotions.length,
          minusEmoCount: minusEmotions.length,
        );
      }).toList();


      setState(() {
        _chartData = [
          charts.Series<SymptomData, String>(
            id: 'Objawy',
            colorFn: (_, __) => charts.MaterialPalette.gray.shadeDefault,
            domainFn: (SymptomData symptoms, _) => symptoms.date,
            measureFn: (SymptomData symptoms, _) => symptoms.symptomCount,
            data: symptomData,
          ),
          charts.Series<SymptomData, String>(
            id: 'Emocje +',
            colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
            domainFn: (SymptomData symptoms, _) => symptoms.date,
            measureFn: (SymptomData symptoms, _) => symptoms.plusEmoCount,
            data: symptomData,
          )
           ..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxis')
           ..setAttribute(charts.rendererIdKey, 'secondary'),
          charts.Series<SymptomData, String>(
            id: 'Emocje -',
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (SymptomData symptoms, _) => symptoms.date,
            measureFn: (SymptomData symptoms, _) => symptoms.minusEmoCount,
            data: symptomData,
          )
           ..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxis')
           ..setAttribute(charts.rendererIdKey, 'secondary'),
        ];
        _isLoading = false;
      });
      
    } else {
      print('Failed to fetch user symptoms: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching user symptoms: $e');
    setState(() {
      _isLoading = false;
    });
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOTODAY',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier New',
            color: Colors.grey,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 71, 0, 119),
      ),
      // body: _isLoading
      //     ? const Center(child: CircularProgressIndicator())
      //   : _chartData.isEmpty
      //       ? const Center(
      //           child: Text(
      //             'Brak danych do wyświetlenia',
      //             style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      //           ),
      //         )
      //       : Padding(
      //           padding: const EdgeInsets.all(16.0),
      //           child: Column(
      //             children: [
      //               const Text(
      //                 'Historia',
      //                 style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      //               ),
      //               const SizedBox(height: 20.0),
                    
      //               Expanded(
      //                 child: charts.OrdinalComboChart(
      //                   _chartData,
      //                   animate: true,
                        
      //                   domainAxis: const charts.OrdinalAxisSpec(
      //                     renderSpec: charts.SmallTickRendererSpec(
      //                       labelRotation: 45, // Rotate labels for better readability
      //                     ),
      //                   ),
      //                   primaryMeasureAxis: const charts.NumericAxisSpec(
      //                     renderSpec: charts.NoneRenderSpec(), // Primary axis configuration
      //                   ),
      //                   secondaryMeasureAxis: charts.NumericAxisSpec(
      //                     renderSpec: charts.NoneRenderSpec(
      //                       // labelStyle: charts.TextStyleSpec(
      //                       //   fontSize: 12, // Font size for secondary axis labels
      //                       //   color: charts.ColorUtil.fromDartColor(Colors.grey), // Label color
      //                       // ),
      //                       // lineStyle: charts.LineStyleSpec(
      //                       //   color: charts.ColorUtil.fromDartColor(Colors.grey), // Gridline color
      //                       // ),
      //                     ),
      //                   ),
      //                   defaultRenderer: charts.BarRendererConfig(
      //                     groupingType: charts.BarGroupingType.grouped,
      //                     strokeWidthPx: 2.0,
      //                     cornerStrategy: const charts.ConstCornerStrategy(10),

      //                   ),
      //                   customSeriesRenderers: [
      //                     charts.LineRendererConfig(
      //                       customRendererId: 'secondary',
      //                       includeArea: true,
      //                       strokeWidthPx: 3.0,
      //                       stacked: false,
      //                       includePoints: true,
      //                       roundEndCaps: true, 
      //                       radiusPx: 5.0,
      //                       areaOpacity: 0.4
      //                     ),
      //                   ],
      //                 behaviors: [

      //                   charts.SeriesLegend(
      //                     position: charts.BehaviorPosition.bottom,
      //                     horizontalFirst: true, 
      //                     cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
      //                     entryTextStyle: const charts.TextStyleSpec(
      //                       color: charts.MaterialPalette.black,
      //                       fontFamily: 'Courier New',
      //                       fontSize: 12,
      //                     ),
      //                   )
      //                 ],
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
    );
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