import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:library_app/app_styles.dart';

import '../models/book.dart';

class BookItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookItem({required this.book, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('global_books')
          .doc(book.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildBookTile(context, 'Error');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildBookTile(context, '0');
        }

        // Convertir el snapshot en un objeto Book
        Book updatedBook = Book.fromFirestore(snapshot.data!);

        return _buildBookTile(
            context, updatedBook.averageRating.toStringAsFixed(1));
      },
    );
  }

  Widget _buildBookTile(BuildContext context, String rating) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: book.coverUrl != null
            ? Image.network(
                book.coverUrl!,
                height: 100,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.book, size: 60, color: AppColors.dark),
        title: Text(book.title),
        subtitle: Text(book.author),
        trailing: Text('Ratings: $rating ★',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: onTap,
      ),
    );
  }
}
