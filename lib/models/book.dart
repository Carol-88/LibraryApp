import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final double rating;
  final String? coverUrl;
  final String? workKey;
  final List<int> ratings; // Lista de ratings de los usuarios

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.rating = 0.0,
    this.coverUrl,
    this.workKey,
    this.ratings = const [], // Inicializamos la lista vacía
  });

  // 📌 Método para calcular el rating promedio
  double get averageRating {
    if (ratings.isEmpty) return 0.0; // Si no hay votos, rating = 0
    int sum = ratings.reduce((a, b) => a + b);
    return sum / ratings.length;
  }

  // 📌 Método para crear un Book desde un snapshot de Firestore
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? 'Título desconocido',
      author: data['author'] ?? 'Autor desconocido',
      description: data['description'] ?? 'No hay descripción disponible',
      coverUrl: data['coverUrl'],
      workKey: data['workKey'],
      ratings: List<int>.from(
          data['ratings'] ?? []), // Convertimos la lista de ratings
    );
  }

  // 📌 Método para convertir un Book a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'workKey': workKey,
      'ratings': ratings,
    };
  }
}
