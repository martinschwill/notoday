// filepath: /Users/martinschwill/Projects/Notoday/notoday/lib/pages/analize.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  List<BarChartGroupData> _chartData = [];
  List<LineChartBarData> _lineData = [];
  List<BarChartGroupData> _chartData2 = [];
  List<dynamic> _slipups = []; 
  List<SymptomData> symptomData = [];
  bool _isLoading = true;
  int _daysRange = 30; // Default to 30 days

  @override
  void initState() {
    super.initState();
    _loadUserSlipups(); 
    _fetchUserSymptoms();
  }

  Future<void> _fetchUserSymptoms([int? daysRange]) async {
  try {
    final payload = json.encode({
      "user_id": widget.userId,
      "days": daysRange ?? _daysRange,
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
        this.symptomData = symptomData;
        _chartData = ChartDataBuilder.buildChartData(symptomData, _slipups, formatToDayMonth);
        _lineData = ChartDataBuilder.buildLineData(symptomData, formatToDayMonth);
        _chartData2 = ChartDataBuilder.buildChartData2(symptomData, formatToDayMonth);
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
  } else {
    await _fetchUserSlipups();
  }
  _isLoading = false; 
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
                      // Date range slider 
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

                      // First Chart - Combined Bar and Line Chart
                      Container(
                        height: 260,
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.center,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        if (true) {
                                          return Transform.rotate(
                                            angle: 45,
                                            child: Text(
                                              ChartDataBuilder.getBottomTitles(symptomData, formatToDayMonth)[value.toInt()],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        }
                                        
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 26,
                                      getTitlesWidget:(value, meta) => 
                                        Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: true,
                                  drawVerticalLine: false,
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                                barGroups: _chartData,
                                maxY: _getMaxY(_chartData).round().toDouble(),
                              ),
                            ),
                            LineChart(
                              LineChartData(
                                lineBarsData: _lineData,
                                minY: 0,
                                maxY: _getMaxY(_chartData),
                                titlesData:FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        if (true) {
                                          return Transform.rotate(
                                            angle: 45,
                                            child: Text(
                                              ChartDataBuilder.getBottomTitles(symptomData, formatToDayMonth)[value.toInt()],
                                              style: const TextStyle(
                                                color: Colors.transparent,
                                                fontSize: 8,
                                              ),
                                            ),
                                          );
                                        }
                                        
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 26,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.transparent,
                                            fontSize: 8,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _legendItem('Objawy', Colors.blueGrey),
                                    const SizedBox(width: 20),
                                    _legendItem('Emocje-', Colors.red),
                                    const SizedBox(width: 20),
                                    _legendItem('Emocje+', Colors.green),
                                  ],
                                ),
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
                      
                      // Second Chart - Bar Chart
                      SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.center,
                            groupsSpace: 8,
                            barTouchData: BarTouchData(
                              enabled: true,
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    if (value.toInt() >= 0 && value.toInt() < ChartDataBuilder.getBottomTitles(_chartData.isEmpty ? [] : symptomData, formatToDayMonth).length) {
                                      return Transform.rotate(
                                        angle: 45,
                                        child: Text(
                                          ChartDataBuilder.getBottomTitles(symptomData, formatToDayMonth)[value.toInt()],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 10,
                                          ),
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
                                  reservedSize: 26,
                                  getTitlesWidget: (value, meta) => 
                                    Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            barGroups: _chartData2,
                            maxY: _getMaxY(_chartData2).round().toDouble(),
                          ),
                        ),
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

Widget _legendItem(String text, Color color) {
  return Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );
}

// Helper method to get maximum Y value for charts
double _getMaxY(List<BarChartGroupData> chartData) {
  if (chartData.isEmpty) return 10; // Default value if no data
  
  double maxValue = 0;
  for (var group in chartData) {
    for (var rod in group.barRods) {
      if (rod.toY > maxValue) {
        maxValue = rod.toY;
      }
    }
  }
  return maxValue * 1.2; // Add 20% margin on top
}
