import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EventBannerSlider extends StatefulWidget {
  const EventBannerSlider({super.key});

  @override
  State<EventBannerSlider> createState() => _EventBannerSliderState();
}

class _EventBannerSliderState extends State<EventBannerSlider> {
  int _currentIndex = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _eventData = [];

  DateTime? _parseDate(String dateStr) {
  try {
    // Handle DD-MM-YYYY specifically
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
  } catch (e) {
    debugPrint('Date parse error for "$dateStr": $e');
  }
  return null;
}

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (mounted && _eventData.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _eventData.length;
        });
      }
    });
  }

  Future<void> _fetchEvents() async {
  try {
    final today = DateTime.now();

    // --- Fetch employee birthdays & anniversaries ---
    final responseProfiles = await http.get(
      Uri.parse('http://localhost:5000/profile'),
    );

    // --- Fetch holidays for current month ---
    final currentMonthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ][today.month - 1];

    final responseHolidays = await http.get(
      Uri.parse(
        'http://localhost:5000/notifications/holiday/employee/ALL?month=$currentMonthName',
      ),
    );

    final List<Map<String, dynamic>> events = [];

    // === 🎂 Birthdays & 🎉 Work Anniversaries (Today) ===
    if (responseProfiles.statusCode == 200) {
      final List employees = json.decode(responseProfiles.body);

      for (var emp in employees) {
        final dob = _parseDate(emp['dob'] ?? '');
        if (dob != null && dob.month == today.month && dob.day == today.day) {
          events.add({
            'title': '🎂 Happy Birthday, ${emp['full_name']}!',
            'subtitle': 'Wishing you a joyful year ahead 🎈',
            'asset': 'assets/event-png/cake.png',
            'bg': const Color.fromARGB(200, 255, 99, 132), // Bright pink
            'textColor': Colors.white,
          });
        }

        // final doj = _parseDate(emp['date_of_appointment'] ?? '');
        // if (doj != null && doj.month == today.month && doj.day == today.day) {
        //   final years = today.year - doj.year;
        //   events.add({
        //     'title': '🎉 Work Anniversary Alert!',
        //     'subtitle':
        //         '${emp['full_name']} completes $years amazing year${years > 1 ? 's' : ''} with us! 👏',
        //     'asset': 'assets/event-png/anniversary.png',
        //     'bg': const Color.fromARGB(190, 255, 186, 8), // Golden tone
        //     'textColor': Colors.white,
        //   });
        // }
      }
    }

    // === 🌴 Holidays (This Month) ===
    if (responseHolidays.statusCode == 200) {
      final List holidays = json.decode(responseHolidays.body);

      for (var holiday in holidays) {
        final msg = holiday['message'] ?? '';
        final parts = msg.split('-');
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final date = parts[1].trim();
          events.add({
            'title': '$name Celebration',
            'subtitle': 'On $date — Enjoy your holiday!',
            'asset': 'assets/event-png/holiday.png',
            'bg': const Color.fromARGB(200, 255, 165, 0), // Festive orange
            'textColor': Colors.white,
          });
        } else {
          events.add({
            'title': '🌴 Upcoming Holiday',
            'subtitle': msg,
            'asset': 'assets/event-png/holiday.png',
            'bg': const Color.fromARGB(200, 255, 165, 0),
            'textColor': Colors.white,
          });
        }
      }
    }

    // === 🏢 Static Events (Permanent) ===
    events.addAll([
      {
        'day': '28',
        'weekday': 'Fri',
        'title': '🤝 New Collaboration with Miro',
        'subtitle': 'Miro Inc. partnership kickoff',
        'time': '11:00 AM',
        'asset': 'assets/event-png/miro.png',
        'bg': const Color.fromARGB(160, 123, 31, 162), // Purple
        'textColor': Colors.white,
      },
      {
        'day': '30',
        'weekday': 'Sun',
        'title': '☁️ Partnership with Microsoft & AWS',
        'subtitle': 'Expanding our cloud ecosystem',
        'time': '02:00 PM',
        'asset': 'assets/event-png/microsoft_aws.png',
        'bg': const Color.fromARGB(176, 33, 150, 243), // Blue
        'textColor': Colors.white,
      },
    ]);

    // === 🪴 Fallback ===
    if (events.isEmpty) {
      events.add({
        'title': 'No Events Today',
        'subtitle': 'Check back tomorrow for new celebrations 🌟',
        'asset': 'assets/event-png/meeting.png',
        'bg': const Color.fromARGB(133, 76, 175, 79),
        'textColor': Colors.white,
      });
    }

    if (!mounted) return;
    setState(() {
      _eventData = events;
    });
  } catch (e) {
    debugPrint('Error fetching events: $e');
  }
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     if (_eventData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _eventData[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 700),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut), child: child);
          },
          child: Container(
            key: ValueKey(data['title']),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data['bg'] as Color?,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Text Section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: TextStyle(
                          color: data['textColor'],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['subtitle'],
                        style: TextStyle(
                          color: data['textColor'],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Image Section
                Expanded(
                  flex: 1,
                  child: Image.asset(
                    data['asset'],
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
