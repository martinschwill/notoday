import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'widgets/app_bar.dart'; 

class HistoryPage extends StatefulWidget {
  final int userId;

  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<charts.Series<SymptomData, String>> _chartData = [];
  List<charts.Series<SymptomData, String>> _chartData2 = [];
  List<dynamic> _slipups = []; 
  bool _isLoading = true;
  int _daysRange = 30; // Default to 30 days

  @override
  void initState() {
    super.initState();
    _fetchUserSlipups(); 
    _fetchUserSymptoms();
  }

  Future<void> _fetchUserSymptoms() async {
  try {
    final payload = json.encode({
      "user_id": widget.userId,
      "days": _daysRange,
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
          _chartData2 = [];
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
          date: item['date'],
          symptomCount: symptoms.length,
          plusEmoCount: plusEmotions.length,
          minusEmoCount: minusEmotions.length,
        );
      }).toList();
  


      setState(() {
        _chartData = [
          charts.Series<SymptomData, String>(
            id: 'Objawy',
            colorFn: (SymptomData symptoms, __) => _slipups.contains(symptoms.date)
              ? charts.ColorUtil.fromDartColor(const Color.fromARGB(255, 223, 2, 2))
              : charts.ColorUtil.fromDartColor(Colors.blueGrey),
            labelAccessorFn: (SymptomData symptoms, __) => 
            _slipups.contains(symptoms.date)
              ? 'Z'
              : '',
            // fillColorFn: (_,__) => charts.ColorUtil.fromDartColor(Colors.black),
            
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
        _chartData2 = [
          charts.Series<SymptomData, String>(
            id: 'Emocje -',
            colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
            domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
            measureFn: (SymptomData symptoms, _) => symptoms.minusEmoCount,
            data: symptomData,
          ),

          charts.Series<SymptomData, String>(
            id: 'Emocje +',
            colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
            domainFn: (SymptomData symptoms, _) => formatToDayMonth(symptoms.date),
            measureFn: (SymptomData symptoms, _) => symptoms.plusEmoCount,
            data: symptomData,
          )
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
  
Future<void> _fetchUserSlipups() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/users/slipups/${widget.userId}'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _slipups = data; 
      });
    } else {
      print('Failed to fetch user slipups: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching user slipups: $e');

  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
        : _chartData.isEmpty
            ? const Center(
                child: Text(
                  'Brak danych do wyświetlenia',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 28.0, right: 28.0, top: 10.0, bottom: 20.0),
                child: Column(
                  children: [
                    const Text(
                      'Historia',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20.0),
                    
                    //Date range slider 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Zakres dni:'),
                        Slider(
                          value: _daysRange.toDouble(),
                          min: 7,
                          max: 60,
                          divisions: 53,
                          label: '$_daysRange',
                          onChanged: (double value) {
                            setState(() {
                              _daysRange = value.round();
                            });
                          },
                          onChangeEnd: (double value) {
                            _fetchUserSymptoms(); // Fetch new data when user stops sliding
                          },
                        ),
                        Text('$_daysRange'),
                      ],
                    ),
                    const SizedBox(height: 10.0),


                    SizedBox(
                      height: 260,
                      child: charts.OrdinalComboChart(
                        _chartData,
                        animate: true,
                        
                        domainAxis: const charts.OrdinalAxisSpec(
                          renderSpec: charts.SmallTickRendererSpec(
                            labelRotation: 45, // Rotate labels for better readability
                          ),
                        ),
                        primaryMeasureAxis: const charts.NumericAxisSpec(
                          renderSpec: charts.GridlineRendererSpec(),
                        ),
                        secondaryMeasureAxis: charts.NumericAxisSpec(
                          renderSpec: charts.NoneRenderSpec(
                            // labelStyle: charts.TextStyleSpec(
                            //   fontSize: 12, // Font size for secondary axis labels
                            //   color: charts.ColorUtil.fromDartColor(Colors.grey), // Label color
                            // ),
                            // lineStyle: charts.LineStyleSpec(
                            //   color: charts.ColorUtil.fromDartColor(Colors.grey), // Gridline color
                            // ),
                          ),
                        ),
                        defaultRenderer: charts.BarRendererConfig(
                          strokeWidthPx: 0.4,
                          cornerStrategy: const charts.ConstCornerStrategy(5),
                          barRendererDecorator: charts.BarLabelDecorator<String>(),

                        ),
                        customSeriesRenderers: [
                          charts.LineRendererConfig(
                            customRendererId: 'secondary',
                            includeArea: true,
                            strokeWidthPx: 1.0,
                            stacked: true,
                            includePoints: false,
                            roundEndCaps: true, 
                            areaOpacity: 0.2,
                          ),
                        ],
                      behaviors: [

                        charts.SeriesLegend(
                          position: charts.BehaviorPosition.top,
                          horizontalFirst: true, 
                          cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
                          entryTextStyle: const charts.TextStyleSpec(
                            color: charts.MaterialPalette.black,
        
                            fontSize: 13,
                          ),
                        ),
                      
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.0),
                    child: Divider(
                      color: Colors.grey, // Line color
                      thickness: 2,      // Line thickness
                      height: 2,         // Space the line takes vertically
                    ),
                  ),
                  SizedBox(
                    height: 260,
                    child: charts.BarChart(
                      _chartData2,
                      animate: true,
                      barGroupingType: charts.BarGroupingType.grouped, // <-- This is important!
                      domainAxis: const charts.OrdinalAxisSpec(
                        renderSpec: charts.SmallTickRendererSpec(
                          labelRotation: 45,
                        ),
                      ),
                      primaryMeasureAxis: const charts.NumericAxisSpec(
                        renderSpec: charts.GridlineRendererSpec(),
                      ),
                      
                      behaviors: [
                        charts.SeriesLegend(),
                      ],
                    )
                  )
                ],
                

              ),
            ),
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

String formatToDayMonth(String dateStr) {
  final date = DateTime.parse(dateStr);
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
}