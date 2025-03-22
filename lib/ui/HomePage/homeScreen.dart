import 'package:ct312h_project/screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../DetailPage/detailScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPageIndex = 0;
  final List<Widget> pages = [
    const HomePage(),
    const SearchPage(),
    const ComingSoonPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Theme.of(context).colorScheme.secondary,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.movie_creation), label: 'Coming Soon'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
        currentIndex: currentPageIndex,
        onTap: (int index) {
          if (index == 3) {
            Navigator.pushNamed(context, '/settings');
          } else {
            setState(() {
              currentPageIndex = index;
            });
          }
        },
      ),
      body: pages[currentPageIndex],
    );
  }
}

// ---------------- HOME PAGE ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<Map<String, dynamic>> trendingMovies = [];
  List<String> localImages = [
    "assets/Poster/p1.jpg",
    "assets/Poster/p2.jpeg",
    "assets/Poster/p3.jpg",
    "assets/Poster/p4.png"
  ];

  @override
  void initState() {
    super.initState();
    fetchMovies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (localImages.isNotEmpty) {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || localImages.isEmpty || !_pageController.hasClients)
        return;

      int nextPage = (_currentPage + 1) % localImages.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _currentPage = nextPage;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchMovies() async {
    final url =
        Uri.parse('http://10.0.2.2:8090/api/collections/movies/records');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trendingMovies = List<Map<String, dynamic>>.from(data['items']);
        });
      } else {
        print(' ${response.statusCode}');
      }
    } catch (e) {
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: 250.0,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: localImages.length,
                  itemBuilder: (context, index) {
                    return Image.asset(
                      localImages[index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Trending Film List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Film',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trendingMovies.length,
                    itemBuilder: (context, index) {
                      final movie = trendingMovies[index];
                      final thumbnailUrl =
                          "http://10.0.2.2:8090/api/files/movies/${movie['id']}/${movie['thumbnail']}";
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                movie: movie,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              height: 200,
                              width: 130,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Search Page ----------------
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> allMovies = [];
  List<Map<String, dynamic>> filteredMovies = [];

  @override
  void initState() {
    super.initState();
    filteredMovies = allMovies;
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final url =
        Uri.parse('http://10.0.2.2:8090/api/collections/movies/records');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allMovies = List<Map<String, dynamic>>.from(data['items']);
          filteredMovies = allMovies;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _filterSearchResults(String query) {
    setState(() {
      filteredMovies = allMovies
          .where((movie) =>
              movie['title'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterSearchResults,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: "Search for a movie...",
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: filteredMovies.length,
            itemBuilder: (context, index) {
              final movie = filteredMovies[index];
              final thumbnailUrl =
                  "http://10.0.2.2:8090/api/files/movies/${movie['id']}/${movie['thumbnail']}";
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  tileColor: Theme.of(context).colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      thumbnailUrl,
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    movie['title'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(movie: movie),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- Coming Soon Page ----------------
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  final List<Map<String, String>> upcomingMovies = const [
    {
      "title": "Avatar 3",
      "image": "assets/Poster/p1.jpg",
      "releaseDate": "December 19, 2025"
    },
    {
      "title": "Spider-Man 4",
      "image": "assets/Poster/p2.jpeg",
      "releaseDate": "July 16, 2024"
    },
    {
      "title": "Deadpool & Wolverine",
      "image": "assets/Poster/p3.jpg",
      "releaseDate": "July 26, 2024"
    },
    {
      "title": "The Batman 2",
      "image": "assets/Poster/p4.png",
      "releaseDate": "October 3, 2025"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text("🎬 Coming Soon",
            style: Theme.of(context).textTheme.bodyLarge),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: upcomingMovies.length,
          itemBuilder: (context, index) {
            final movie = upcomingMovies[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Card(
                color: Theme.of(context).colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                      child: Image.asset(
                        movie["image"]!,
                        height: 120,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movie["title"]!,
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 5),
                          Text(
                            "Release Date: ${movie["releaseDate"]!}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.notifications,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
