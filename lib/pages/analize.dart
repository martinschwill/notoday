import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart'; 

class AnalyzePage extends StatefulWidget {
  final int userId;
  final String userName; // Add this line to accept userName

  const AnalyzePage({super.key, required this.userId, required this.userName});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  List<charts.Series<SymptomData, String>> _chartData = [];
  List<charts.Series<SymptomData, String>> _chartData2 = [];
  List<dynamic> _slipups = []; 
  bool _isLoading = true;
  int _daysRange = 30; // Default to 30 days

  @override
  void initState() {
    super.initState();
    _loadUserSlipups(); 
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
        _chartData = buildChartData(symptomData, _slipups, formatToDayMonth);
        _chartData2 = buildChartData2(symptomData, formatToDayMonth);
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
        print('Fetched slipups: $_slipups');
      });
    } else {
      print('Failed to fetch user slipups: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching user slipups: $e');

  }
}

Future<void> _loadUserSlipups() async {
  final prefs = await SharedPreferences.getInstance();
  final slipups = prefs.getStringList('slipups'); 
  if (slipups != null && slipups.isNotEmpty) {
    setState(() {
      _slipups = slipups;
    });
  }else{
    await _fetchUserSlipups();
  }
 _isLoading = false ; 
}

Future<List<SymptomData>>_getRawSymptomData() async {
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
       
        return [];
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
      return symptomData; 
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
  return []; 
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'NOTODAY'),
      endDrawer: CustomDrawer(userName: widget.userName, userId: widget.userId), 
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
                  ),
                  
                  const SizedBox(height: 10.0),

                  CustomButton(
                    onPressed: () async {

                      // Perform the analysis and show the results 
                      // Compare last 3 days average with the average of picked days range
                      String title = "Analiza emocji i objawów"; 
                      final daysData = await _getRawSymptomData();
                      final symptomsRaw = daysData.map((data) => data.symptomCount).toList();
                      final emoPlusRaw = daysData.map((data) => data.plusEmoCount).toList();
                      final emoMinusRaw = daysData.map((data) => data.minusEmoCount).toList();
                      
                      String message = performCalculation(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange);

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(title),
                            content: Text(message),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                      
                    },
                    text: "Analizuj")
                    
                ],
                

              ),
            ),
    );
  }
}

String formatToDayMonth(String dateStr) {
  final date = DateTime.parse(dateStr);
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
}