import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiaryDetailPage extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onUpdated;
  final Function(Map<String, dynamic>)? onEdit;

  const DiaryDetailPage({
    super.key,
    required this.entry,
    required this.onUpdated,
    this.onEdit,
  });

  // Define a consistent color palette for consistency
  static const Color primaryColor = Color(0xFFFF6F61); // A vibrant red-orange
  static const Color accentColor = Color(0xFF4ECDC4); // A calming turquoise
  static const Color backgroundColor = Color(0xFFF9F9F9); // Light background
  static const Color textColor = Color(0xFF4A4A4A); // Dark grey for text
  static const Color cardColor = Colors.white; // White for cards

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor, // Dialog background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)), // Rounded dialog corners
        title: const Text("Delete Entry", style: TextStyle(color: textColor)),
        content: const Text("Are you sure you want to delete this diary entry?", style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: accentColor)), // Accent color for cancel
          ),
          ElevatedButton( // Changed to ElevatedButton for prominence
            onPressed: () async {
              // Also delete image from storage if it exists
              if (entry['image_url'] != null) {
                try {
                  final imagePath = Uri.parse(entry['image_url']).pathSegments.last;
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    await Supabase.instance.client.storage.from('diary_images').remove(['$userId/$imagePath']);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete image: $e')),
                    );
                  }
                }
              }
              await Supabase.instance.client.from('diary_entries').delete().eq('id', entry['id']);
              if (context.mounted) Navigator.pop(context); // Close dialog first
              if (context.mounted) Navigator.pop(context); // go back to previous page after deletion
              onUpdated(); // reload entries on home page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Red color for delete
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editEntry(BuildContext context) {
    if (onEdit != null) {
      onEdit!(entry); // Call the passed onEdit function
    }
    // No need to pop here, as _addOrEditEntry on DiaryHomePage will show a dialog
    // on top, and onUpdated will be called when it closes.
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(entry['created_at']);
    return Scaffold(
      backgroundColor: backgroundColor, // Overall background color
      appBar: AppBar(
        title: const Text(
          "Diary Entry",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor, // AppBar color
        foregroundColor: Colors.white, // AppBar title/icon color
        elevation: 4.0, // Add subtle shadow
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Rounded bottom corners for AppBar
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded), // Modern back icon
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // Make content scrollable
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Emoji
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1), // Light accent background
                borderRadius: BorderRadius.circular(10), // Rounded corners
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry['emoji'] ?? '📝', // Fallback emoji
                    style: const TextStyle(fontSize: 32), // Slightly larger emoji
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, d MMMM y').format(date), // Full month name
                    style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              entry['title'],
              style: const TextStyle(
                fontSize: 28, // Larger title
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 15),

            // Content
            Text(
              entry['content'],
              style: TextStyle(
                fontSize: 18, // Slightly larger content font
                color: textColor.withOpacity(0.9),
                height: 1.5, // Line height for better readability
              ),
            ),
            const SizedBox(height: 25),

            // Image Display
            if (entry['image_url'] != null && entry['image_url'].isNotEmpty)
              Center(
                child: ClipRRect( // Rounded corners for the image
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.network(
                    entry['image_url'],
                    height: 250, // Larger image height
                    width: double.infinity, // Take full width
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                      );
                    },
                  ),
                ),
              ),
            if (entry['image_url'] != null && entry['image_url'].isNotEmpty)
              const SizedBox(height: 25),

            // Spacer to push buttons to the bottom
            const SizedBox(height: 20), // Added fixed spacing instead of Spacer for better control

            // Action Buttons
            Align( // Align buttons to the right
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min, // Wrap content
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _editEntry(context),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white), // Themed icon
                    label: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor, // Accent color for edit
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded buttons
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white), // Themed icon
                    label: const Text("Delete", style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Strong red for delete
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 3,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}