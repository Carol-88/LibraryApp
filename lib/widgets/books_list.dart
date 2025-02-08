import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/screens/book_detail_screen.dart';
import 'package:library_app/services/user_service.dart';

class BookListWidget extends StatelessWidget {
  final String userId;
  final String listName;
  final UserService userService = UserService();

  BookListWidget({required this.userId, required this.listName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: userService.getUserListStream(userId, listName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hay libros en tu lista de $listName.'));
        }
        final books = snapshot.data!.docs;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final bookData = books[index].data() as Map<String, dynamic>;
            final book = Book.fromJson(bookData);
            return ListTile(
              leading: book.coverUrl != null
                  ? Image.network(book.coverUrl!,
                      height: 100, fit: BoxFit.cover)
                  : Icon(Icons.book, size: 70),
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                onSelected: (option) async {
                  if (option == 'delete') {
                    await userService.removeBookFromList(
                        userId, listName, books[index].id);
                  } else {
                    await userService.moveBookToList(
                        userId, listName, option, books[index].id, bookData);
                  }
                },
                itemBuilder: (context) => [
                  if (listName != 'favoritos')
                    PopupMenuItem(
                        value: 'favoritos', child: Text('Mover a Favoritos')),
                  if (listName != 'pendientes')
                    PopupMenuItem(
                        value: 'pendientes', child: Text('Mover a Pendientes')),
                  if (listName != 'leidos')
                    PopupMenuItem(
                        value: 'leidos', child: Text('Mover a Leídos')),
                  PopupMenuItem(
                      value: 'delete', child: Text('Eliminar de la lista')),
                ],
                icon: Icon(Icons.more_vert),
              ),
            );
          },
        );
      },
    );
  }
}
