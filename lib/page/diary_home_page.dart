import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'diary_detail_page.dart';
import 'profile_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  final Map<DateTime, List<Map<String, dynamic>>> _diaryEntries = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _currentIndex = 0;

  List<Map<String, dynamic>> _getAllDiaryEntries() {
    final allEntries = <Map<String, dynamic>>[];
    final sortedDates = _diaryEntries.keys.toList()..sort();
    for (var date in sortedDates) {
      for (var entry in _diaryEntries[date]!) {
        allEntries.add({
          'date': date,
          'title': entry['title'],
          'content': entry['content'],
          'emoji': entry['emoji'],
        });
      }
    }
    return allEntries;
  }

  void _openDiaryDetail(BuildContext context, int globalIndex) {
    final allEntries = _getAllDiaryEntries();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailPage(
          entries: allEntries,
          currentIndex: globalIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF4A4A4A)),
        title: const Text(
          'My Cozy Diary',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Color(0xFF333333)),
              weekendTextStyle: const TextStyle(color: Color(0xFF333333)),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFF6F61),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (_diaryEntries[date] != null && _diaryEntries[date]!.isNotEmpty) {
                  return const Icon(Icons.emoji_emotions, color: Color(0xFFFF6F61), size: 18);
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildDiaryList()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF6F61),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            _showNewDiaryDialog();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(
                  totalEntries: _getAllDiaryEntries().length,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'New Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    final entries = _diaryEntries[_selectedDay] ?? [];
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries for this day', style: TextStyle(color: Color(0xFF555555))),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: entry['imagePath'] != null
                ? Image.file(File(entry['imagePath']), width: 50, height: 50, fit: BoxFit.cover)
                : Text(entry['emoji'], style: const TextStyle(fontSize: 24)),
            title: Text(entry['title']),
            subtitle: Text(entry['content']),
            onTap: () {
              final allEntries = _getAllDiaryEntries();
              final tappedEntry = {
                'date': _selectedDay,
                'title': entry['title'],
                'content': entry['content'],
                'emoji': entry['emoji'],
              };
              final globalIndex = allEntries.indexWhere((e) =>
                  e['date'] == tappedEntry['date'] &&
                  e['title'] == tappedEntry['title'] &&
                  e['content'] == tappedEntry['content']);
              _openDiaryDetail(context, globalIndex);
            },
          ),
        );
      },
    );
  }

  void _showNewDiaryDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedEmoji = '😊';
    File? selectedImage;

    Future<void> _pickImage(StateSetter setState) async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Diary Entry'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        '😀','😁','😂','🤣','😃','😄','😎','😊','🥰','😢','😭','🥹'
                      ].map((emoji) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: 28,
                              backgroundColor: selectedEmoji == emoji
                                  ? const Color(0xFFFFC1A1)
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F61),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _pickImage(setState),
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 10),
                    selectedImage != null
                        ? Image.file(selectedImage!, height: 150)
                        : const Text('No image selected.')
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F61),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _diaryEntries.putIfAbsent(_selectedDay, () => []);
                      _diaryEntries[_selectedDay]!.add({
                        'title': titleController.text,
                        'content': contentController.text,
                        'emoji': selectedEmoji,
                        'imagePath': selectedImage?.path,
                      });
                    });
                    Navigator.of(context).pop();
                    _showPositiveMessage();
                  },
                  child: const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showPositiveMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Great!'),
        content: const Text('Keep writing and explore your thoughts!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }
}
