import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteScreen extends StatefulWidget {
  final String userId; 
  const FavoriteScreen({super.key, required this.userId});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favoriteMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("🔍 UserID in FavoriteScreen: ${widget.userId}"); 
    loadFavorites();
  }

  Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}

  Future<void> loadFavorites() async {
    final url = Uri.parse('http://10.0.2.2:8090/api/collections/users/records/${widget.userId}?expand=favorites');

    try {
      final response = await http.get(url);
       print("📡 Fetching data from: $url");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          favoriteMovies = List<Map<String, dynamic>>.from(data['expand']['favorites'] ?? []);
          isLoading = false;
        });
      } else {
        print("${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print(" $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFromFavorites(String movieId) async {
    final url = Uri.parse('http://10.0.2.2:8090/api/collections/users/records/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> favorites = data['favorites'] ?? [];

        if (favorites.contains(movieId)) {
          favorites.remove(movieId);
          final updateResponse = await http.patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'favorites': favorites}),
          );

          if (updateResponse.statusCode == 200) {
            loadFavorites(); 
          } else {
            print("${updateResponse.body}");
          }
        }
      }
    } catch (e) {
      print(" $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteMovies.isEmpty
              ? const Center(child: Text("You don't have any favorite movies yet."))
              : ListView.builder(
                  itemCount: favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final movie = favoriteMovies[index];
                    final thumbnailUrl =
                        "http://10.0.2.2:8090/api/files/movies/${movie['id']}/${movie['thumbnail']}";
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(thumbnailUrl, width: 50, height: 70, fit: BoxFit.cover),
                        ),
                        title: Text(movie['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeFromFavorites(movie['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
