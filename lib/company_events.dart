import 'package:flutter/material.dart';
import 'sidebar.dart'; // ✅ Shared Sidebar layout

class CompanyEventsScreen extends StatelessWidget {
  const CompanyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Events',
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Events',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ListView(
                children: const [
                  EventTile(
                    day: '20',
                    weekday: 'Mon',
                    title: 'Development planning',
                    company: 'W3 Technologies',
                    time: '12:02 PM',
                  ),
                  EventTile(
                    day: '21',
                    weekday: 'Wed',
                    title: 'Development planning',
                    company: 'W3 Technologies',
                    time: '12:20 PM',
                  ),
                  EventTile(
                    day: '24',
                    weekday: 'Fri',
                    title: 'Development planning',
                    company: 'W3 Technologies',
                    time: '12:30 PM',
                  ),
                  EventTile(
                    day: '25',
                    weekday: 'Tue',
                    title: 'Development planning',
                    company: 'W3 Technologies',
                    time: '12:40 PM',
                  ),
                  EventTile(
                    day: '28',
                    weekday: 'Fri',
                    title: 'New Collaboration with Miro',
                    company: 'Miro Inc.',
                    time: '11:00 AM',
                  ),
                  EventTile(
                    day: '30',
                    weekday: 'Sun',
                    title: 'Celebrating Partnership with Microsoft and AWS',
                    company: 'Microsoft / AWS',
                    time: '02:00 PM',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  final String day;
  final String weekday;
  final String title;
  final String company;
  final String time;

  const EventTile({
    super.key,
    required this.day,
    required this.weekday,
    required this.title,
    required this.company,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2F41),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  weekday,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  company,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
