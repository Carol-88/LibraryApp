import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/models/book.dart'; // Importa el modelo Book
import 'package:library_app/screens/book_detail_screen.dart';
import 'package:library_app/services/open_library_service.dart';
import 'package:library_app/widgets/book_item.dart'; // Importa el widget BookItem

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OpenLibraryService _libraryService = OpenLibraryService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _searchResults = []; // Cambia a List<Book>
  bool _isLoading = false;

  void _logout() async {
    await _auth.signOut();
    setState(() {});
  }

  Future<void> _searchBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results =
          await _libraryService.searchBooks(query: _searchController.text);
      // Convierte los resultados en instancias de Book
      setState(() {
        _searchResults = results.map((book) => Book.fromJson(book)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar libros: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Library App",
            style: GoogleFonts.lexend().copyWith(color: AppColors.accent),
          ),
        ),
        backgroundColor: AppColors.background,
        actions: [
          if (user == null) ...[
            IconButton(
              icon: Icon(Icons.login, color: AppColors.secondary),
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            IconButton(
              icon: Icon(Icons.person_add, color: AppColors.secondary),
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.person, color: AppColors.secondary),
              onPressed: () {
                Navigator.pushNamed(context, '/user');
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: AppColors.secondary),
              onPressed: _logout,
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar libros',
                labelStyle:
                    TextStyle(color: AppColors.background), // Color del label
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.dark, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.background, width: 1.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: AppColors.dark),
                  onPressed: _searchBooks,
                ),
              ),
              cursorColor: AppColors.dark,
              style: TextStyle(color: AppColors.background),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.dark),
                        strokeWidth: 6.0, // Aumenta el grosor del spinner
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.dark,
                        thickness: 1.0,
                      ), // Línea divisoria entre elementos
                      itemBuilder: (context, index) {
                        final book = _searchResults[index];
                        return BookItem(
                          book: book,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookDetailScreen(book: book),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
