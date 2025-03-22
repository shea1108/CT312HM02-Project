import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController _nameController = TextEditingController();
  String? userId;
  File? _avatarImage;
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    if (userId != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:8090/api/collections/users/records/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
        });
      } else {
        print("Failed to load user data");
      }
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    } else {
      print('Error picking image');
    }
  }

  Future<String?> _uploadAvatar(File avatar) async {
    if (userId == null) {
      print("User ID is null. Cannot upload avatar.");
      return null;
    }

    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('http://10.0.2.2:8090/api/collections/users/records/$userId'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatar.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseData);
        print('Avatar uploaded successfully: $jsonData');
        return jsonData['avatar']; // ✅ Get correct filename
      } else {
        print('Failed to upload avatar: ${response.statusCode}');
        print(responseData);
        return null;
      }
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? avatarFilename;
      if (_avatarImage != null) {
        avatarFilename = await _uploadAvatar(_avatarImage!);
        if (avatarFilename == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar upload failed')),
          );
          return;
        }
      }

      var url = Uri.parse('http://10.0.2.2:8090/api/collections/users/records/$userId');
      var response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          if (avatarFilename != null) 'avatar': avatarFilename, // ✅ Use correct filename
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        print("Profile update failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while updating profile')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        title: const Text("Edit Profile"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!)
                          : null,
                      child: _avatarImage == null
                          ? const Icon(Icons.camera_alt, color: Colors.white, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }
}
