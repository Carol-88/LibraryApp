// lib/widgets/book_item.dart
import 'package:flutter/material.dart';

import '../models/book.dart'; // Importa el modelo Book

class BookItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookItem({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: book.coverUrl != null
            ? Image.network(
                book.coverUrl!,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.book,
                color: Colors.grey,
              ),
        title: Text(book.title),
        subtitle: Text(book.author),
        trailing: Text('Rating: ${book.rating}'),
        onTap: onTap,
      ),
    );
  }
}
