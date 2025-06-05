// filepath: /Users/martinschwill/Projects/Notoday/notoday/lib/pages/analize.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_imports.dart'; 
import '../widgets/trend_indicator.dart';
import '../widgets/trend_summary_widget.dart';
import '../modules/analytics.dart';

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
  List<PieChartSectionData> _emotionsPieData = []; // Added for pie chart
  List<PieChartSectionData> _dailyEmotionsPieData = []; // For single day emotions
  List<dynamic> _slipups = []; 
  List<SymptomData> symptomData = [];
  bool _isLoading = true;
  int _daysRange = 30; // Default to 30 days
  int _selectedDayIndex = -1; // Index of selected day, -1 means no selection

  // Added structure to hold emotion totals
  late EmotionsTotal _emotionsTotal;
  EmotionsTotal? _selectedDayEmotions; // For the selected day's emotions
  
  @override
  void initState() {
    super.initState();
    _loadUserSlipups(); 
    _fetchUserSymptoms();
  }

  // Modified to use updated ChartDataBuilder methods
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
            _selectedDayIndex = -1;
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
          
          // Default to the most recent day (index 0 if data is sorted by date desc)
          if (symptomData.isNotEmpty) {
            _selectedDayIndex = 0;
            _selectedDayEmotions = EmotionsTotal(
              symptomData[0].plusEmoCount, 
              symptomData[0].minusEmoCount
            );
            _dailyEmotionsPieData = _generateDailyPieData(_selectedDayEmotions!);
          } else {
            _selectedDayIndex = -1;
          }
          
          // Update charts with selected day
          _updateCharts();
          
          _emotionsTotal = _calculateEmotionsTotal(symptomData); // Calculate emotions total
          _emotionsPieData = _generatePieData(_emotionsTotal); // Generate pie chart data
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
  
  // Update charts with current data and selection
  void _updateCharts() {
    _chartData = _buildChartDataWithSelection(symptomData, _slipups, _selectedDayIndex);
    _lineData = ChartDataBuilder.buildLineData(symptomData, formatToDayMonth);
    _chartData2 = _buildChartData2WithSelection(symptomData, _selectedDayIndex);
  }
  
  // Build chart data with selected day highlighted
  List<BarChartGroupData> _buildChartDataWithSelection(
    List<SymptomData> symptomData, 
    List<dynamic> slipups, 
    int selectedIndex
  ) {
    return symptomData.asMap().entries.map((entry) {
      int index = entry.key;
      SymptomData data = entry.value;
      
      bool hasSlipup = slipups.contains(data.date);
      bool isSelected = index == selectedIndex;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.symptomCount.toDouble(),
            gradient: hasSlipup
              ? LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 157, 150, 6),
                    Color.fromARGB(255, 168, 192, 11)
                  ],
                )
              : null, 
            color: isSelected ? Colors.blue : Colors.blueGrey,
            width: isSelected ? 12 : 8, // Make selected bar wider
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: isSelected
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: (_getMaxY(_chartData) * 0.05).round().toDouble(),
                  color: Colors.blue.withOpacity(0.2),
                )
              : null,
          ),
        ],
      );
    }).toList();
  }

  // Build emotions chart data with stacked bars showing both emotion types
  List<BarChartGroupData> _buildChartData2WithSelection(
    List<SymptomData> symptomData,
    int selectedIndex
  ) {
    return symptomData.asMap().entries.map((entry) {
      int index = entry.key;
      SymptomData data = entry.value;
      bool isSelected = index == selectedIndex;
      
      return BarChartGroupData(
        x: index,
        groupVertically: true, // Stack bars vertically
        barRods: [
          // Positive emotions first (bottom stack)
          BarChartRodData(
            toY: data.plusEmoCount.toDouble(),
            color: isSelected 
              ? const Color.fromARGB(255, 63, 145, 66).withOpacity(1)
              : const Color.fromARGB(255, 63, 145, 66).withOpacity(0.7),
            width: isSelected ? 16 : 12, // Wider bar for stacked display
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: isSelected
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: (_getMaxY(_chartData2) * 0.05).round().toDouble(),
                  color: Colors.green.withOpacity(0.1),
                )
              : null,
          ),
          // Negative emotions on top of positive (top stack)
          BarChartRodData(
            toY: data.minusEmoCount.toDouble(),
            fromY: data.plusEmoCount.toDouble(), // Start from where positive emotions end
            color: isSelected 
              ? const Color.fromARGB(255, 222, 54, 42).withOpacity(1)
              : const Color.fromARGB(255, 222, 54, 42).withOpacity(0.7),
            width: isSelected ? 16 : 12, // Wider bar for stacked display
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            backDrawRodData: isSelected
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: (_getMaxY(_chartData2) * 0.05).round().toDouble(),
                  color: Colors.red.withOpacity(0.1),
                )
              : null,
          ),
        ],
      );
    }).toList();
  }

  // Updated selection handler
  void _selectDay(int dayIndex) {
    if (dayIndex >= 0 && dayIndex < symptomData.length) {
      setState(() {
        // Toggle selection if the same day is selected again
        if (_selectedDayIndex == dayIndex) {
          _selectedDayIndex = -1;
          _selectedDayEmotions = null;
          _dailyEmotionsPieData = [];
        } else {
          _selectedDayIndex = dayIndex;
          final dayData = symptomData[dayIndex];
          _selectedDayEmotions = EmotionsTotal(dayData.plusEmoCount, dayData.minusEmoCount);
          _dailyEmotionsPieData = _generateDailyPieData(_selectedDayEmotions!);
        }
        
        // Update charts to reflect selection
        _updateCharts();
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

// Cache key for the raw symptom data
String? _lastDataCacheKey;
List<SymptomData>? _cachedSymptomData;

// Get raw symptom data with caching for better performance
Future<List<SymptomData>> _getRawSymptomData() async {
  // Check cache first - only use cache if days range hasn't changed
  String cacheKey = '${widget.userId}_$_daysRange';
  if (_cachedSymptomData != null && _lastDataCacheKey == cacheKey) {
    return _cachedSymptomData!;
  }
  
  try {
    final payload = json.encode({
      "user_id": widget.userId,
      "days": _daysRange,
    });
    
    // Show loading indicator for longer fetches
    bool needsLoadingIndicator = _cachedSymptomData == null;
    if (needsLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/days/past'),
      headers: {"Content-Type": "application/json"},
      body: payload,
    );

    // Hide loading indicator
    if (needsLoadingIndicator) {
      setState(() {
        _isLoading = false;
      });
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      if (data.isEmpty) {
        _cachedSymptomData = [];
        _lastDataCacheKey = cacheKey;
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
      
      // Cache the data
      _cachedSymptomData = symptomData;
      _lastDataCacheKey = cacheKey;
      
      return symptomData;
    } else {
      print('Failed to fetch user symptoms: ${response.statusCode}');
      // Return cached data if available, empty list otherwise
      return _cachedSymptomData ?? [];
    }
  } catch (e) {
    print('Error fetching user symptoms: $e');
    // Return cached data if available, empty list otherwise
    return _cachedSymptomData ?? [];
  }
}

  // Method to calculate emotion totals from symptom data
  EmotionsTotal _calculateEmotionsTotal(List<SymptomData> data) {
    int totalPositive = 0;
    int totalNegative = 0;
    
    for (var symptom in data) {
      totalPositive += symptom.plusEmoCount;
      totalNegative += symptom.minusEmoCount;
    }
    
    return EmotionsTotal(totalPositive, totalNegative);
  }

  // Method to generate pie chart sections from emotions total
  List<PieChartSectionData> _generatePieData(EmotionsTotal emotionsTotal) {
    return [
      PieChartSectionData(
        value: emotionsTotal.positiveEmotions.toDouble(),
        title: '${(emotionsTotal.positivePercentage * 100).round()}%',
        color: const Color.fromARGB(255, 68, 159, 71), // Green
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: emotionsTotal.negativeEmotions.toDouble(),
        title: '${(emotionsTotal.negativePercentage * 100).round()}%',
        color: const Color.fromARGB(255, 225, 55, 43), // Red
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // Generate donut chart for daily emotions
  List<PieChartSectionData> _generateDailyPieData(EmotionsTotal emotionsTotal) {
    final total = emotionsTotal.total;
    
    // If no emotions for the day, return a gray circle
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.withOpacity(0.3),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.transparent,
          ),
        ),
      ];
    }
    
    return [
      PieChartSectionData(
        value: emotionsTotal.positiveEmotions.toDouble(),
        title: '${(emotionsTotal.positivePercentage * 100).round()}%',
        color: const Color.fromARGB(255, 68, 159, 71), // Green
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: emotionsTotal.negativeEmotions.toDouble(),
        title: '${(emotionsTotal.negativePercentage * 100).round()}%',
        color: const Color.fromARGB(255, 225, 55, 43), // Red
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
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
              : Column(
                  children: [
                    // Fixed top area with the slider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Zakres dni:'),
                          Expanded(
                            child: Slider(
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
                          ),
                          Text('$_daysRange'),
                        ],
                      ),
                    ),

                    // Scrollable middle area with charts
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 12.0),
                            
                            // Trend Summary Widget - shows all trends at a glance
                            FutureBuilder<List<SymptomData>>(
                              future: _getRawSymptomData(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 100,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const SizedBox();
                                }
                                
                                final daysData = snapshot.data!;
                                final symptomsRaw = daysData.map((data) => data.symptomCount).toList();
                                final emoPlusRaw = daysData.map((data) => data.plusEmoCount).toList();
                                final emoMinusRaw = daysData.map((data) => data.minusEmoCount).toList();
                                
                                return TrendSummaryWidget(
                                  symptomsData: symptomsRaw,
                                  posEmotionsData: emoPlusRaw, 
                                  negEmotionsData: emoMinusRaw,
                                  daysRange: _daysRange,
                                );
                              },
                            ),
                            
                            const SizedBox(height: 16.0),

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
                                        handleBuiltInTouches: true,
                                        touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                                          if (touchResponse != null && 
                                              event is FlTapUpEvent && 
                                              touchResponse.spot != null) {
                                            _selectDay(touchResponse.spot!.touchedBarGroupIndex);
                                          }
                                        },
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
                                          _legendItem('Emocje-', const Color.fromARGB(255, 225, 55, 43)),
                                          const SizedBox(width: 20),
                                          _legendItem('Emocje+', const Color.fromARGB(255, 68, 159, 71)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 9.0, bottom: 30.0),
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
                                    handleBuiltInTouches: true,
                                    touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
                                      if (touchResponse != null && 
                                          event is FlTapUpEvent && 
                                          touchResponse.spot != null) {
                                        _selectDay(touchResponse.spot!.touchedBarGroupIndex);
                                      }
                                    },
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

                            // Add divider before pie chart
                            const Padding(
                              padding: EdgeInsets.only(top: 30.0, bottom: 20.0),
                              child: Divider(
                                color: Colors.grey,
                                thickness: 2,
                                height: 2,
                              ),
                            ),

                            // Add daily emotions donut chart title
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Emocje z dnia: ${_selectedDayIndex >= 0 && _selectedDayIndex < symptomData.length ? formatToDayMonth(symptomData[_selectedDayIndex].date) : "Nie wybrano"}',
                                style: const TextStyle(
                                  fontSize: 16.0, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),

                            // Add daily emotions donut chart
                            SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: _selectedDayIndex < 0
                                ? const Center(child: Text('Kliknij na wykresie, aby zobaczyć emocje z wybranego dnia'))
                                : Column(
                                    children: [
                                      Expanded(
                                        child: PieChart(
                                          PieChartData(
                                            sections: _dailyEmotionsPieData,
                                            centerSpaceRadius: 40, // Larger center space to make it a donut
                                            sectionsSpace: 2,
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                              enabled: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Add legend for donut chart
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _legendItem('Przyjemne', const Color.fromARGB(255, 68, 159, 71)),
                                          const SizedBox(width: 30),
                                          _legendItem('Nieprzyjemne', const Color.fromARGB(255, 225, 55, 43)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Add daily totals
                                      _selectedDayEmotions != null && _selectedDayEmotions!.total > 0
                                          ? Text(
                                              'Emocje przyjemne: ${_selectedDayEmotions!.positiveEmotions}, '
                                              'Emocje nieprzyjemne: ${_selectedDayEmotions!.negativeEmotions}',
                                              style: const TextStyle(fontSize: 12),
                                            )
                                          : const Text('Brak emocji dla wybranego dnia', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                            ),
                                const SizedBox(height: 20.0),
                            // Add divider before pie chart
                                                        const Padding(
                              padding: EdgeInsets.only(top: 9.0, bottom: 30.0),
                              child: Divider(
                                color: Colors.grey, // Line color
                                thickness: 2,      // Line thickness
                                height: 2,         // Space the line takes vertically
                              ),
                            ),
                            // Add pie chart title
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Stosunek emocji przyjemnych i nieprzyjemnych',
                                style: TextStyle(
                                  fontSize: 16.0, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),

                            // Add pie chart
                            SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: _emotionsPieData.isEmpty
                                ? const Center(child: Text('Brak danych do wyświetlenia'))
                                : Column(
                                    children: [
                                      Expanded(
                                        child: PieChart(
                                          PieChartData(
                                            sections: _emotionsPieData,
                                            centerSpaceRadius: 40,
                                            sectionsSpace: 2,
                                            pieTouchData: PieTouchData(
                                              touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                              enabled: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Add legend for pie chart
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _legendItem('Przyjemne', const Color.fromARGB(255, 68, 159, 71)),
                                          const SizedBox(width: 30),
                                          _legendItem('Nieprzyjemne', const Color.fromARGB(255, 225, 55, 43)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Add totals
                                      _emotionsTotal.total > 0
                                          ? Text(
                                              'Emocje przyjemne: ${_emotionsTotal.positiveEmotions}, '
                                              'Emocje nieprzyjemne: ${_emotionsTotal.negativeEmotions}',
                                              style: const TextStyle(fontSize: 12),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                            ),
                            
        
                         
                            

                            // Add space at the bottom for better scrolling experience
                            const SizedBox(height: 20.0),
                          ],
                        ),
                      ),
                    ),

                    // Fixed bottom button area
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: CustomButton(
                        onPressed: () async {
                          // Perform the analysis and show the results 
                          // Compare last 3 days average with the average of picked days range
                          String title = "Analiza emocji i objawów"; 
                          final daysData = await _getRawSymptomData();
                          final symptomsRaw = daysData.map((data) => data.symptomCount).toList();
                          final emoPlusRaw = daysData.map((data) => data.plusEmoCount).toList();
                          final emoMinusRaw = daysData.map((data) => data.minusEmoCount).toList();
                          
                          // Get the text analysis
                          String message = performCalculation(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange);
                          
                          // Get trend analysis objects for visual indicators
                          final symptomsTrend = analyzeTrend(symptomsRaw, _daysRange);
                          final emoPlusTrend = analyzeTrend(emoPlusRaw, _daysRange);
                          final emoMinusTrend = analyzeTrend(emoMinusRaw, _daysRange);

                          // Show enhanced dialog with visual trend indicators
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(title),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Symptom trend display
                                      const Text(
                                        "Objawy:",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          TrendIndicator(
                                            trend: symptomsTrend.direction,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Zmiana: ${symptomsTrend.percentChange > 0 ? '+' : ''}${symptomsTrend.percentChange.toStringAsFixed(1)}%",
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      
                                      // Positive emotions trend
                                      const Text(
                                        "Emocje przyjemne:",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          TrendIndicator(
                                            trend: emoPlusTrend.direction,
                                            size: 22,
                                            upColor: Colors.green,
                                            downColor: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Zmiana: ${emoPlusTrend.percentChange > 0 ? '+' : ''}${emoPlusTrend.percentChange.toStringAsFixed(1)}%",
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      
                                      // Negative emotions trend
                                      const Text(
                                        "Emocje nieprzyjemne:",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          TrendIndicator(
                                            trend: emoMinusTrend.direction,
                                            size: 22,
                                            upColor: Colors.red,
                                            downColor: Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Zmiana: ${emoMinusTrend.percentChange > 0 ? '+' : ''}${emoMinusTrend.percentChange.toStringAsFixed(1)}%",
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      
                                      // Detailed analysis text
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Szczegółowa analiza:",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(message),
                                    ],
                                  ),
                                ),
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
                        text: "Analizuj",
                      ),
                    ),
                  ],
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
          borderRadius: BorderRadius.circular(5),
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

// Data structure to hold emotion totals for pie chart
class EmotionsTotal {
  final int positiveEmotions;
  final int negativeEmotions;
  
  EmotionsTotal(this.positiveEmotions, this.negativeEmotions);
  
  int get total => positiveEmotions + negativeEmotions;
  double get positivePercentage => total == 0 ? 0 : positiveEmotions / total;
  double get negativePercentage => total == 0 ? 0 : negativeEmotions / total;
}
