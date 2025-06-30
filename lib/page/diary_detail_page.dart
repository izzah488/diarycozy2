import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';


class DiaryDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final int currentIndex;

  const DiaryDetailPage(
      {super.key, required this.entries, required this.currentIndex});

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Diary Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry['emoji'], style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              DateFormat('EEEE, d MMMM yyyy').format(entry['date']),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(entry['title'],
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

if (entry['imagePath'] != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Image.file(File(entry['imagePath']), height: 200),
  ),


            Text(entry['content'], style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < widget.entries.length - 1
                      ? () => setState(() => _currentIndex++)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
