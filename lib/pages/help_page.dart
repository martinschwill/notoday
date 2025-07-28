import 'package:flutter/material.dart'; 
import '../common_imports.dart'; 

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'POMOC'), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main title
            Text(
              'Jak korzystać z aplikacji Notoday',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // App description
            _buildSection(
              '📱 O aplikacji',
              'NOTODAY to aplikacja do zarządzania trzeźwieniem, zdrowiem psychicznym i śledzenia samopoczucia, która pomaga użytkownikom w codziennym monitorowaniu swoich emocji i objawów głodu.',
            ),

            // Main functions
            _buildSection(
              '🔧 Główne funkcje aplikacji',
              '',
              children: [
                _buildFeature(
                  '📝 Dziennik objawów i emocji',
                  '• Codzienne rejestrowanie poziomu objawów\n'
                  '• Śledzenie przyjemnych i nieprzyjemnych emocji\n'
                  // '• Możliwość dodawania notatek tekstowych do każdego wpisu\n'
                  '• Szczegółowy widok wszystkich dni oraz trendów',
                ),
                _buildFeature(
                  '📊 Analiza i trendy',
                  '• Automatyczne analizy trendów w samopoczuciu\n'
                  '• Wykrywanie wzrostowych, spadkowych lub stabilnych tendencji\n'
                  '• Procentowe zmiany w stosunku do poprzednich okresów\n'
                  '• Graficzne przedstawienie danych w czasie',
                ),
                _buildFeature(
                  '🛠️ Zestaw narzędzi pomocowych',
                  '• Telefon: Szybki dostęp do ważnych numerów (terapeuta, kryzysowa linia, rodzina, trzeźwiejący znajomi)\n'
                  '• Działania: Lista pomocnych technik i ćwiczeń (oddechowe, mindfulness, relaksacyjne, rekreacyjne, sportowe)\n'
                  '• Miejsca: Lokalizacje wspierające (terapie, mitingi, parki, kawiarnie, miejsca spokoju)',
                ),
              ],
            ),

            // How to use
            _buildSection(
              '📋 Jak korzystać z aplikacji',
              '',
              children: [
                _buildStep('1', 'Rejestracja i logowanie', 'Utwórz konto lub zaloguj się do istniejącego konta.'),
                _buildStep('2', 'Codzienne wpisy', 'Regularnie oceniaj swoje objawy i emocje. Zaznaczaj każdy objaw i emocje, nawet jeżeli są subtelne lub chwilowe.'),
                _buildStep('3', 'Budowanie zestawu narzędzi', 'Dodaj numery telefonów, własne techniki radzenia sobie i bezpieczne miejsca (konkretne adresy).'),
                _buildStep('4', 'Korzystanie z analiz', 'Używaj przycisk "Analizuj" jak najczęściej, aby otrzymać szczegółowe informacje o trendach. Zwracaj uwagę na alerty!'),
                _buildStep('5', 'Śledzenie postępów', 'Przeglądaj analizy i trendy w swoim samopoczuciu. Zwracaj uwagę na gwałtowne zmiany oraz które emocje wywołują objawy głodu.'),
              ],
            ),

            // Interactive features
            _buildSection(
              '🎯 Interaktywność zestawu narzędzi',
              '',
              children: [
                _buildTip('Twórz własne narzędzia', 'Od Ciebie zależy, jakie numery, adresy i techniki dodasz do swojego zestawu. Korzystaj z nich w momentach kryzysowych!'),
                _buildInteractiveFeature('📞', 'Dotknij telefon', 'Automatyczne wywołanie numeru'),
                _buildInteractiveFeature('⚡', 'Dotknij działanie', 'Wyświetlenie szczegółów techniki'),
                _buildInteractiveFeature('📍', 'Dotknij miejsce', 'Otwarcie lokalizacji w Mapach Google'),
              ],
            ),

            // Benefits
            _buildSection(
              '✨ Korzyści z używania aplikacji',
              '',
              children: [
                _buildBenefit('🧠', 'Świadomość własnych wzorców emocjonalnych'),
                _buildBenefit('⚠️', 'Łatwiejsze rozpoznawanie okresów kryzysu'),
                _buildBenefit('🆘', 'Szybki dostęp do wsparcia w trudnych momentach'),
                _buildBenefit('👨‍⚕️', 'Dane do dzielenia z terapeutą lub lekarzem'),
                _buildBenefit('💪', 'Motywacja do regularnej samoobserwacji'),
              ],
            ),

            // Tips
            _buildSection(
              '💡 Wskazówki',
              '',
              children: [
                _buildTip('Regularność', 'Staraj się dodawać wpisy codziennie o podobnej porze. Ustaw sobie przypomnienie w sekcji Przypomnij'),
                _buildTip('Szczerość', 'Bądź szczery/a w ocenach - to pomoże w lepszym zrozumieniu siebie.'),
                // _buildTip('Notatki', 'Dodawaj szczegółowe notatki o wydarzeniach dnia i swoich reakcjach.'),
                _buildTip('Analiza', 'Regularnie przeglądaj wykresy aby zauważyć wzorce.'),
                _buildTip('Narzędzia', 'Aktualizuj swój zestaw narzędzi - dodawaj nowe kontakty, miejsca i techniki. Usuwaj te, które nie działają.'),
              ],
            ),

            // Summary
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Podsumowanie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aplikacja służy jako cyfrowy towarzysz trzeźwości w podróży ku lepszemu zdrowiu psychicznemu i fizycznemu. Pomaga w organizacji wsparcia i zrozumieniu własnych potrzeb emocjonalnych oraz sytuacji niesprzyjających trzeźwieniu.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, {List<Widget>? children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
        ],
        if (children != null) ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveFeature(String emoji, String action, String result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$action → ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              result,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String emoji, String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tips_and_updates,
              size: 16,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}