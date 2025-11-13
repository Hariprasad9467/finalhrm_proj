import 'package:flutter/material.dart';
import 'attendance_status.dart';
import 'sidebar.dart'; // ✅ Reusable sidebar layout

class AttendanceLoginPage extends StatelessWidget {
  const AttendanceLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Attendance System',
      body: Column(
        children: [
          const SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 50,
                      ),
                      children: [
                        TextSpan(
                          text: 'Mark ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 105, 45, 208),
                            shadows: [
                              Shadow(
                                offset: Offset(5.5, 3.5),
                                blurRadius: 3.0,
                                color: Color.fromARGB(255, 82, 21, 187),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(5.5, 3.5),
                                blurRadius: 5.0,
                                color: Color.fromARGB(255, 98, 45, 189),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // LOGIN & LOGOUT buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AttendanceScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF692DD0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.black),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 3.0,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AttendanceScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF692DD0),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.black),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'LOGOUT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2.0,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}