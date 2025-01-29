import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/widgets/rating_bar.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailScreen({super.key, required this.book});

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Map<String, int> _listCounts;
  late String workKey;

  @override
  void initState() {
    super.initState();
    _listCounts = {'favoritos': 0, 'pendientes': 0, 'leídos': 0};
    workKey = widget.book['workKey']?.substring(7) ?? '';
    _fetchListCounts(workKey);
  }

  Future<void> _addBookToList(String listName, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Inicia sesión para añadir libros a tus listas.")),
      );
      return;
    }

    final userId = user.uid;
    final sanitizedWorkKey =
        widget.book['key']?.replaceAll('/works/', '') ?? '';
    final userListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listName)
        .collection('books');

    try {
      final snapshot =
          await userListRef.where('workKey', isEqualTo: sanitizedWorkKey).get();

      if (snapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El libro ya está en la lista $listName.")),
        );
        return;
      }

      await userListRef.add({
        'workKey': sanitizedWorkKey,
        'title': widget.book['title'] ?? 'Título desconocido',
        'author': widget.book['author'] ?? 'Autor desconocido',
        'cover': widget.book['cover'],
        'average_rating': widget.book['average_rating'] ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Libro añadido a la lista $listName.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al añadir el libro a la lista.")),
      );
    }
  }

  Future<void> _fetchListCounts(String workKey) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('global_books')
          .doc(workKey)
          .get();

      if (doc.exists) {
        setState(() {
          _listCounts = {
            'favoritos': doc['listCount']['favoritos'] ?? 0,
            'pendientes': doc['listCount']['pendientes'] ?? 0,
            'leídos': doc['listCount']['leídos'] ?? 0,
          };
        });
      }
    } catch (e) {
      print("Error al obtener datos del libro: $e");
    }
  }

  Future<bool> _userCanVote() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userLists = ['favoritos', 'leídos'];
    for (final list in userLists) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(list)
          .collection('books')
          .doc('workKey')
          .get();
      if (snapshot.exists) return true;
    }
    return false;
  }

  Future<double> _getBookRating() async {
    final doc = await FirebaseFirestore.instance
        .collection('global_books')
        .doc(widget.book['workKey'])
        .get();
    if (doc.exists) {
      return doc.data()?['rating']?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _rateBook(int rating, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('global_books')
        .doc(widget.book['workKey'])
        .set({'rating': rating}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Has votado con $rating estrellas.")),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Información"),
        content: Text(
          "Solo los usuarios con este libro en sus listas de Favoritos o Leídos pueden votar. "
          "Inicia sesión y agrega este libro a una de estas listas para calificarlo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.book['title']) ?? 'Detalles del libro'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.accent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book['title'] ?? 'Título desconocido',
                style: GoogleFonts.lexend(
                  textStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.book['author'] ?? 'Autor desconocido',
                style: GoogleFonts.lexend(
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: 16),
              widget.book['cover'] != null
                  ? Image.network(
                      'https://covers.openlibrary.org/b/id/${widget.book['cover']}-L.jpg',
                      height: 200,
                    )
                  : Icon(Icons.book, size: 100),
              SizedBox(height: 16),
              Text(
                "Valoración media: ${widget.book['average_rating']?.toStringAsFixed(1) ?? 'N/A'} ⭐",
                style: GoogleFonts.lexend(
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              FutureBuilder<double>(
                future: _getBookRating(),
                builder: (context, snapshot) {
                  double rating = snapshot.data ?? 0.0;
                  return Row(
                    children: [
                      Rating(
                        value: rating,
                        onValueClicked: (int value) async {
                          bool canVote = await _userCanVote();
                          if (canVote) {
                            await _rateBook(value, context);
                          } else {
                            _showInfoDialog(context);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.grey),
                        onPressed: () => _showInfoDialog(context),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _addBookToList('favorites', context),
                child: Text("Añadir a Favoritos"),
              ),
              ElevatedButton(
                onPressed: () => _addBookToList('read', context),
                child: Text("Añadir a Leídos"),
              ),
              ElevatedButton(
                onPressed: () => _addBookToList('to_read', context),
                child: Text("Añadir a Por Leer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
