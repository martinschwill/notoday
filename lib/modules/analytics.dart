
class Analytics {
  final int userId;
  final String? userName; 

  const Analytics({
    required this.userId,
    this.userName,
  });
  
}

double averageOfSymptoms(List<int> dailySymptoms, int days) {
  if (dailySymptoms.isEmpty) return 0;
  final recent = dailySymptoms.reversed.take(days).toList(); 
  if (recent.isEmpty) return 0;
  final sum = recent.reduce((a, b) => a + b);
  return sum / recent.length;
}


/// Returns "upward", "downward", or "stable" trend for the last [days] of symptom counts.
String symptomTrend(List<int> dailySymptoms, int days) {
  final recent = dailySymptoms.take(days).toList();
  if (recent.length < 2) return "stable";

  // Linear regression: y = a + bx, we care about b (the slope)
  final n = recent.length;
  final xMean = (n - 1) / 2.0;
  final yMean = recent.reduce((a, b) => a + b) / n;

  double numerator = 0;
  double denominator = 0;
  for (int i = 0; i < n; i++) {
    numerator += (i - xMean) * (recent[i] - yMean);
    denominator += (i - xMean) * (i - xMean);
  }
  final slope = denominator == 0 ? 0 : numerator / denominator;

  if (slope > 0.1) return "upward";
  if (slope < -0.1) return "downward";
  return "stable";
}

String performCalculation(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange) {
  String message = "Objawy: "; 
  double avgSympt = averageOfSymptoms(symptomsRaw, 3) / averageOfSymptoms(symptomsRaw, _daysRange);
  if (avgSympt >= 1.2) {
    message += "Wzrost o ${((avgSympt) * 100).toStringAsFixed(2)}% \n";
  } else if (avgSympt <= 0.8) {
    message += "Spadek o ${((avgSympt) * 100).toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  message += "Trend objawów: ";
  String symptTrend = symptomTrend(symptomsRaw, _daysRange);
  if (symptTrend == "upward") {
    message += "Wzrostowy \n\n";
  } else if (symptTrend == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }
  
  message += "Emocje przyjemne: ";
  double avgEmoPlus = averageOfSymptoms(emoPlusRaw, 3) / averageOfSymptoms(emoPlusRaw, _daysRange);
  if (avgEmoPlus >= 1.2) {
    message += "Wzrost o ${((avgEmoPlus) * 100).toStringAsFixed(2)}% \n";
  } else if (avgEmoPlus <= 0.8) {
    message += "Spadek o ${((avgEmoPlus) * 100).toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  message += "Trend emocji przyjemnych: ";
  String emoPlusTrend = symptomTrend(emoPlusRaw, _daysRange); 
  if (emoPlusTrend == "upward") {
    message += "Wzrostowy \n\n";
  } else if (emoPlusTrend == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }
  message += "Emocje nieprzyjemne: ";
  double avgEmoMinus = averageOfSymptoms(emoMinusRaw, 3) / averageOfSymptoms(emoMinusRaw, _daysRange);
  if (avgEmoMinus >= 1.2) {
    message += "Wzrost o ${((avgEmoMinus) * 100).toStringAsFixed(2)}% \n";
  } else if (avgEmoMinus <= 0.8) {
    message += "Spadek o ${((avgEmoMinus) * 100).toStringAsFixed(2)}% \n";
  } else {
    message += "Stabilne \n";
  }
  message += "Trend emocji nieprzyjemnych: ";
  String emoMinusTrend = symptomTrend(emoMinusRaw, _daysRange);
  if (emoMinusTrend == "upward") {
    message += "Wzrostowy \n\n";
  } else if (emoMinusTrend == "downward") {
    message += "Spadkowy \n\n";
  } else {
    message += "Stabilny \n\n";
  }

  return message;
}


List<String> performWarning(symptomsRaw, emoPlusRaw, emoMinusRaw, _daysRange) {
  List <String> alert = []; 
  if (averageOfSymptoms(symptomsRaw, 3) / averageOfSymptoms(symptomsRaw, _daysRange) >= 1.2 && symptomTrend(symptomsRaw, _daysRange) == "upward") {
     alert.add('symptoms'); 
  }
  if (averageOfSymptoms(emoMinusRaw, 3) / averageOfSymptoms(emoMinusRaw, _daysRange) >= 1.2 && symptomTrend(emoMinusRaw, _daysRange) == "upward") {
    alert.add('emoPlus'); 
  }
  if (averageOfSymptoms(emoPlusRaw, 3) / averageOfSymptoms(emoPlusRaw, _daysRange) >= 1.2 && symptomTrend(emoPlusRaw, _daysRange) == "upward") {
    alert.add('emoMinus'); 
  }
  return alert;  
  }


  ///TO DO: USER IT SOMEWHERE IN THE APP TO CREATE A WARNING