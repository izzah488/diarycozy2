import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'profile_page.dart' as profile_page; // Alias to avoid naming conflicts
import 'diary_detail_page.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  // Map to store diary entries grouped by date for calendar display
  Map<DateTime, List<Map<String, dynamic>>> _diaryEntries = {};
  // List to store all fetched diary entries, used for overall count and sorting
  List<Map<String, dynamic>> _allFetchedEntries = [];
  // Currently selected day in the calendar
  DateTime _selectedDay = DateTime.now();
  // The day currently focused in the calendar view
  DateTime _focusedDay = DateTime.now();
  // Index for the bottom navigation bar
  int _currentIndex = 0;

  // Define a consistent color palette for the UI
  static const Color primaryColor = Color(0xFFFF6F61); // A vibrant red-orange
  static const Color accentColor = Color(0xFF4ECDC4); // A calming turquoise
  static const Color backgroundColor = Color(0xFFF9F9F9); // Light background
  static const Color textColor = Color(0xFF4A4A4A); // Dark grey for text
  static const Color cardColor = Colors.white; // White for cards

  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries(); // Fetch diary entries when the page initializes
  }

  // Fetches diary entries from Supabase for the current user
  Future<void> _fetchDiaryEntries() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        // If no user is logged in, do not proceed
        return;
      }

      // Query 'diary_entries' table for entries belonging to the current user,
      // ordered by creation date in descending order.
      final response = await Supabase.instance.client
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Filter out entries where 'created_at' might be null (though it should ideally not be)
      final validEntries = response.where((e) => e['created_at'] != null).toList();

      // Update the state if the widget is still mounted
      if (mounted) {
        setState(() {
          _allFetchedEntries = List<Map<String, dynamic>>.from(validEntries);
          _groupEntriesByDate(); // Group the fetched entries by date for calendar display
        });
      }
    } catch (e) {
      // Show a snackbar if there's an error fetching entries
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Error fetching entries: $e')),
        );
      }
    }
  }

  // Groups fetched diary entries by their creation date (day only)
  void _groupEntriesByDate() {
    _diaryEntries = {}; // Clear previous entries
    for (var entry in _allFetchedEntries) {
      final entryDate = DateTime.parse(entry['created_at']);
      // Create a DateTime object with only year, month, and day for grouping
      final dateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
      // Add the entry to the list for its corresponding date
      _diaryEntries.putIfAbsent(dateOnly, () => []).add(entry);
    }
  }

  // Returns all diary entries, sorted by creation date
  List<Map<String, dynamic>> _getAllDiaryEntries() {
    final sortedEntries = List<Map<String, dynamic>>.from(_allFetchedEntries);
    sortedEntries.sort((a, b) => DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
    return sortedEntries;
  }

  // Allows the user to pick an image from the gallery
  Future<void> _pickImage(StateSetter setDialogState, Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Call the callback function with the picked image file
      setDialogState(() => onPicked(File(picked.path)));
    }
  }

  // Shows a dialog to add a new diary entry or edit an existing one
  Future<void> _addOrEditEntry({Map<String, dynamic>? entry}) async {
    final isEdit = entry != null; // Determine if it's an edit operation
    final titleController = TextEditingController(text: entry?['title'] ?? '');
    final contentController = TextEditingController(text: entry?['content'] ?? '');
    String selectedEmoji = entry?['emoji'] ?? '😀'; // Default emoji
    File? selectedImage; // For newly picked image
    String? existingImageUrl = entry?['image_url']; // For existing image URL

    await showDialog(
      context: this.context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (setStateContext, setDialogState) {
          return AlertDialog(
            backgroundColor: cardColor, // Set dialog background color
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded corners for dialog
            title: Text(isEdit ? 'Edit Entry' : 'New Diary Entry', style: const TextStyle(color: textColor)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: accentColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: primaryColor, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    cursorColor: primaryColor,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: const TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: accentColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: primaryColor, width: 2.0),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    maxLines: 3,
                    cursorColor: primaryColor,
                  ),
                  const SizedBox(height: 15),
                  // Emoji selection
                  Wrap(
                    spacing: 8,
                    children: ['😀', '🥳', '😔', '✨', '😤', '😊', '😢', '😍', '😠', '🤔', '😭', '😴', '🥰', '😎']
                        .map((e) => GestureDetector(
                              onTap: () => setDialogState(() => selectedEmoji = e),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedEmoji == e ? primaryColor.withOpacity(0.3) : null,
                                  borderRadius: BorderRadius.circular(5.0), // Slight rounding for emoji background
                                ),
                                padding: const EdgeInsets.all(2.0),
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 15),
                  // Image picker button
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(setDialogState, (file) {
                      selectedImage = file;
                      existingImageUrl = null; // Clear existing image if a new one is picked
                    }),
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text('Pick Image', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor, // Button color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), // Rounded button
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  // Display selected or existing image
                  if (selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect( // Clip image to have rounded corners
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                      ),
                    )
                  else if (existingImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect( // Clip image to have rounded corners
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(existingImageUrl!, height: 100, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: primaryColor)),
              ),
              ElevatedButton(
               onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            selectedImage = File(picked.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                    ),
                    if (selectedImage != null) Image.file(selectedImage!, height: 100)
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;

                    String? imageUrl;
                    if (selectedImage != null) {
                      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                      await Supabase.instance.client.storage
                          .from('diary_images')
                          .upload(path, selectedImage!);
                      imageUrl = Supabase.instance.client.storage.from('diary_images').getPublicUrl(path);
                    }

                    await Supabase.instance.client.from('diary_entries').insert({
                      'user_id': user.id,
                      'title': titleController.text.trim(),
                      'content': contentController.text.trim(),
                      'emoji': selectedEmoji,
                      'image_url': imageUrl,
                      'created_at': DateTime.now().toIso8601String(),
                      'created_at': DateTime(
  _selectedDay.year,
  _selectedDay.month,
  _selectedDay.day,
  DateTime.now().hour,
  DateTime.now().minute,
  DateTime.now().second,
).toIso8601String(),

                    });

                    if (mounted) {
                      Navigator.pop(context);
                      _fetchDiaryEntries();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Overall background color
      appBar: AppBar(
        backgroundColor: primaryColor, // AppBar color
        iconTheme: const IconThemeData(color: Colors.white), // Icons on AppBar
        title: const Text(
          'My Cozy Diary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // AppBar title color and bold
        ),
        elevation: 4.0, // Add subtle shadow to AppBar
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Rounded bottom corners for AppBar
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 5.0, // Shadow for the calendar card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners for calendar card
              ),
              color: cardColor, // Calendar card background
              child: TableCalendar(
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => _selectedDay.year == day.year &&
                                      _selectedDay.month == day.month &&
                                      _selectedDay.day == day.day,
                firstDay: DateTime(2020), // Start date for calendar
                lastDay: DateTime(2030), // End date for calendar
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false, // Hide format button (e.g., '2 weeks', 'month')
                  titleCentered: true, // Center the month/year title
                  titleTextStyle: TextStyle(color: textColor, fontSize: 18.0, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: accentColor),
                  rightChevronIcon: Icon(Icons.chevron_right, color: accentColor),
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: accentColor, // Color for today's date
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: primaryColor, // Color for selected date
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.white),
                  defaultTextStyle: TextStyle(color: textColor),
                  weekendTextStyle: TextStyle(color: textColor), // Keep weekend text same as default for a cleaner look
                  outsideTextStyle: TextStyle(color: Colors.grey),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // Check if there are diary entries for this date
                    final entriesForDate = _diaryEntries[DateTime(date.year, date.month, date.day)];
                    if (entriesForDate != null && entriesForDate.isNotEmpty) {
                      return const Positioned(
                        right: 1,
                        bottom: 1,
                        child: Icon(Icons.fiber_manual_record, color: primaryColor, size: 8), // Small dot marker
                      );
                    }
                    return null; // No marker if no entries
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildDiaryList()), // Display list of diary entries for the selected day
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor, // Selected item color in bottom nav
        unselectedItemColor: textColor.withOpacity(0.6), // Unselected item color
        backgroundColor: cardColor, // Bottom nav background color
        elevation: 8.0, // Shadow for bottom nav
        type: BottomNavigationBarType.fixed, // Ensure items are fixed and don't shift
        onTap: (index) {
          setState(() => _currentIndex = index); // Update selected index
          if (index == 1) {
            _addOrEditEntry(); // Open dialog to add new entry
          } else if (index == 2) {
            // Navigate to the ProfilePage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => profile_page.ProfilePage(
                  // Pass the total number of entries to the profile page
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

  // Builds the list of diary entries for the selected day
  Widget _buildDiaryList() {
    // Get entries for the selected day, or an empty list if none
    final entries = _diaryEntries[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? [];
    if (entries.isEmpty) {
      // Display a message if no entries for the day
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: textColor.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text(
              'No entries for this day. Write something!',
              style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 16),
            ),
          ],
        ),
      );
    }
    // Build a ListView of diary entry cards
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Card(
            elevation: 3.0, // Shadow for each diary entry card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0), // Rounded corners for entry cards
            ),
            color: cardColor, // Card background
            child: ListTile(
              contentPadding: const EdgeInsets.all(12.0), // Padding inside the ListTile
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1), // Light background for leading icon/image
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners for the container
                ),
                child: Center(
                  child: entry['image_url'] != null
                      ? ClipRRect( // Clip image to have rounded corners
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(entry['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                        )
                      : Text(entry['emoji'], style: const TextStyle(fontSize: 28)), // Larger emoji
                ),
              ),
              title: Text(
                entry['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                entry['content'],
                style: TextStyle(color: textColor.withOpacity(0.8)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: accentColor, size: 18), // A subtle arrow
              onTap: () => _openDiaryDetail(context, entry), // Open detail page on tap
            ),
          ),
        );
      },
    );
  }
}