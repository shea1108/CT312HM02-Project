import 'dart:convert';

import 'package:flutter/material.dart';
import '../../screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  String? userId;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    if (userId != null) {
      checkIfFavorite();
    }
  }

  Future<void> checkIfFavorite() async {
    if (userId == null) return;

    final url =
        Uri.parse('http://10.0.2.2:8090/api/collections/users/records/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> favorites = data['favorites'] ?? [];
        setState(() {
          isFavorite = favorites.contains(widget.movie['id']);
        });
      }
    } catch (e) {
      print("Error checking favorite: $e");
    }
  }

  Future<void> toggleFavorite() async {
    if (userId == null) return;

    final url =
        Uri.parse('http://10.0.2.2:8090/api/collections/users/records/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> favorites = List.from(data['favorites'] ?? []);

        if (isFavorite) {
          favorites.remove(widget.movie['id']);
        } else {
          favorites.add(widget.movie['id']);
        }
        final updateResponse = await http.patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'favorites': favorites}),
        );

        if (updateResponse.statusCode == 200) {
          setState(() {
            isFavorite = !isFavorite;
          });
        } else {
          print("Failed to update favorites: ${updateResponse.body}");
        }
      }
    } catch (e) {
      print("Error updating favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Image.network(
                "http://10.0.2.2:8090/api/files/movies/${widget.movie['id']}/${widget.movie['thumbnail']}",
                width: 220,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              widget.movie['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Nội dung mô tả phim
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.movie['desciption'],
                style:
                    TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/video_player',
                        arguments: widget.movie['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        "Watch Now",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: toggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
