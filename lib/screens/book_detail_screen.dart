import 'package:cloud_firestore/cloud_firestore.dart'; // Corregir a cloud_firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/services/books_service.dart';
import 'package:library_app/widgets/rating_bar.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => BookDetailScreenState();
}

class BookDetailScreenState extends State<BookDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BooksService _booksService = BooksService();
  late Map<String, int> _listCounts;
  double? _userRating;

  void _logout() async {
    await _auth.signOut();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _listCounts = {'favoritos': 0, 'pendientes': 0, 'leidos': 0};
    if (widget.book.workKey != null) {
      _fetchListCounts(widget.book.workKey!.substring(7));
      _fetchUserRating();
    }
  }

  Future<void> _fetchListCounts(String workKey) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> bookDoc =
          await FirebaseFirestore.instance
              .collection('global_books')
              .doc(workKey)
              .get();

      if (bookDoc.exists && bookDoc.data() != null) {
        final data = bookDoc.data()!;
        if (data.containsKey('listCount')) {
          setState(() {
            _listCounts = {
              'favoritos': data['listCount']['favoritos'] ?? 0,
              'pendientes': data['listCount']['pendientes'] ?? 0,
              'leidos': data['listCount']['leidos'] ?? 0,
            };
          });
        }
      }
    } catch (e) {
      print("Error al obtener datos del libro: $e");
    }
  }

  Future<void> _fetchUserRating() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.book.workKey == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('global_books')
          .doc(widget.book.workKey!.substring(7));

      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('ratings')) {
          setState(() {
            _userRating = (data['ratings'][user.uid] ?? 0.0).toDouble();
          });
        }
      }
    } catch (e) {
      print("Error al obtener la valoración del usuario: $e");
    }
  }

  Future<void> _rateBook(double rating) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.book.workKey == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('global_books')
          .doc(widget.book.workKey!.substring(7));

      bool canVote = await _userCanVote();
      if (!canVote) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes tener este libro en tus listas de favoritos o leídos para poder votarlo.',
            ),
          ),
        );
        return;
      }

      await docRef.set({
        'ratings': {
          user.uid: rating,
        }
      }, SetOptions(merge: true));

      setState(() {
        _userRating = rating;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al valorar el libro: $e'),
        ),
      );
    }
  }

  Future<bool> _userCanVote() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userLists = ['favoritos', 'leidos'];
    for (final list in userLists) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .doc(list)
            .collection('books')
            .where('workKey', isEqualTo: widget.book.workKey)
            .get();

        if (snapshot.docs.isNotEmpty) return true;
      } catch (e) {
        print("Error al verificar lista del usuario: $e");
      }
    }
    return false;
  }

  Future<void> _addToList(String listName, BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes iniciar sesión para agregar libros a tus listas.'),
        ),
      );
      return;
    }

    try {
      if (widget.book.workKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faltan datos para agregar el libro.')),
        );
        return;
      }

      // Usa _booksService para llamar al método
      await _booksService.addBookToList(
        user.uid,
        listName,
        {
          'title': widget.book.title,
          'author': widget.book.author,
          'cover': widget.book.coverUrl,
          'workKey': widget.book.workKey,
          'description': widget.book.description,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Libro añadido a "$listName".'),
        ),
      );

      if (widget.book.workKey != null) {
        _fetchListCounts(widget.book.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al añadir el libro a la lista: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: GoogleFonts.lexend().copyWith(color: AppColors.accent),
        ),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Autor: ${widget.book.author}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Center(
                child: widget.book.coverUrl != null
                    ? Image.network(
                        widget.book.coverUrl!,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book, size: 100),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Center(
                  child: const Text(
                    'Valorar el libro:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Rating(
                    value: _userRating ?? 0.0,
                    onValueClicked: (newRating) {
                      _rateBook(newRating.toDouble());
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                widget.book.description?.isNotEmpty == true
                    ? widget.book.description!
                    : "No hay descripción disponible",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildGlobalStatsCard(),
              const SizedBox(height: 16),
              if (user != null) ...[
                const Text(
                  'Añadir a listas:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttons,
                      ),
                      onPressed: () => _addToList('favoritos', context),
                      child: const Text('Favoritos'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttons,
                      ),
                      onPressed: () => _addToList('pendientes', context),
                      child: const Text('Pendientes'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttons,
                      ),
                      onPressed: () => _addToList('leidos', context),
                      child: const Text('Leídos'),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Inicia sesión para agregar libros a tus listas.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Estadísticas Globales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _listCounts.values.any((v) => v > 0) ? 1 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatItem(
                    icon: Icons.favorite_border,
                    label: 'Favoritos',
                    count: _listCounts['favoritos'] ?? 0,
                  ),
                  const Divider(thickness: 1),
                  _buildStatItem(
                    icon: Icons.watch_later,
                    label: 'Pendientes',
                    count: _listCounts['pendientes'] ?? 0,
                  ),
                  const Divider(thickness: 1),
                  _buildStatItem(
                    icon: Icons.check_circle_outline,
                    label: 'Leídos',
                    count: _listCounts['leidos'] ?? 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
