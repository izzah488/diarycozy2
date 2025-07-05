import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Import provider
import '../theme_provider.dart'; // Import your ThemeProvider

class ProfilePage extends StatefulWidget {
  final int totalEntries;

  const ProfilePage({super.key, required this.totalEntries});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? profileImage;
  String? _profileImageUrl;
  String? _email;
  bool _loading = true;
  bool _isUploadingImage = false; // State for image upload loading

  // Define a consistent color palette for the UI
  static const Color primaryColor = Color(0xFFFF6F61); // A vibrant red-orange
  static const Color accentColor = Color(0xFF4ECDC4); // A calming turquoise
  static const Color backgroundColor = Color(0xFFF9F9F9); // Light background
  static const Color textColor = Color(0xFF4A4A4A); // Dark grey for text
  static const Color cardColor = Colors.white; // White for cards

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Loads the user's profile data from Supabase
  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
      }
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      // Fetch profile data
      final response = await Supabase.instance.client
          .from('profiles') // Assuming your profile table is named 'profiles'
          .select('email, profile_image_url') // Select the columns you need
          .eq('id', user.id)
          .single(); // Expecting a single row

      // If a profile exists, set the state
      setState(() {
        _email = response['email'] as String?;
        _profileImageUrl = response['profile_image_url'] as String?;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      // Handle cases where the profile might not exist (PGRST116) or other DB errors
      if (e.code == 'PGRST116' || e.message.contains('0 rows')) {
        // Profile not found, create a new one
        print('Profile not found for user ${user.id}. Creating new profile...');
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'email': user.email, // Use the user's email from auth
            'profile_image_url': null, // Initialize with null image
          });
          setState(() {
            _email = user.email;
            _profileImageUrl = null;
            _loading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New profile created successfully!')),
            );
          }
        } catch (createError) {
          print('Error creating profile: $createError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating profile: $createError')),
            );
          }
          setState(() {
            _loading = false;
          });
        }
      } else {
        // Other PostgrestException
        print('Error loading profile: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: ${e.message}')),
          );
        }
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      // Catch any other unexpected errors
      print('An unexpected error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  // Uploads a new profile image to Supabase storage
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
      }
      setState(() {
        _isUploadingImage = false;
      });
      return;
    }

    try {
      final file = File(pickedFile.path);
      final fileName = basename(file.path);
      final filePath = '${user.id}/profile/$fileName'; // Unique path for each user's profile image

      // Upload image
      final StorageResponse response = await Supabase.instance.client.storage
          .from('profiles') // Assuming you have a bucket named 'profile_images'
          .upload(filePath, file,
              fileOptions: const FileOptions(upsert: true)); // Upsert to replace existing

      if (response.error != null) {
        throw response.error!.message;
      }

      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(filePath)
          .data;

      // Update the user's profile_image_url in the database
      await Supabase.instance.client
          .from('profiles') // Update the 'profiles' table
          .update({'profilesurl': publicUrl})
          .eq('id', user.id);

      setState(() {
        _profileImageUrl = publicUrl;
        profileImage = file; // Set the local file for immediate display
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  // Signs the user out
  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        // Navigate back to the login page after signing out
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Remove all routes from the stack
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: backgroundColor, // Apply background color
      appBar: AppBar(
        title: const Text('My Profile',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)), // White text
        backgroundColor: primaryColor, // Apply primary color
        elevation: 0, // No shadow
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: accentColor.withOpacity(0.2),
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null) as ImageProvider<Object>?,
                        child: profileImage == null && _profileImageUrl == null
                            ? Icon(Icons.person, size: 80, color: accentColor)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _isUploadingImage
                            ? const CircularProgressIndicator(
                                color: primaryColor)
                            : GestureDetector(
                                onTap: _uploadProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // User Email Display
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.email, color: accentColor, size: 28),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Email: ${_email ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 18, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Total Diary Entries Display
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.book, color: accentColor, size: 28),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Total Diary Entries: ${widget.totalEntries}',
                              style: const TextStyle(
                                  fontSize: 18, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Theme Toggle (if you want to keep it simple)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.brightness_6,
                              color: accentColor, size: 28),
                          const SizedBox(width: 15),
                          const Text(
                            'Dark Mode',
                            style: TextStyle(fontSize: 18, color: textColor),
                          ),
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme(); // Toggles globally
                            },
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20), // Spacing between buttons

                  // Log Out Button
                  ElevatedButton.icon(
                    onPressed: () => _signOut(context), // Call the _signOut method
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Use a distinct color for logout
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      elevation: 5,
                      minimumSize: const Size.fromHeight(55),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
