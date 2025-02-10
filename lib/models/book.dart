import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final double rating;
  final String? coverUrl;
  final String? workKey;
  final List<double> ratings; // Lista de ratings de los usuarios

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.rating = 0,
    this.coverUrl,
    this.workKey,
    this.ratings = const [], // Inicializamos la lista vacía
  });

  // 📌 Método para calcular el rating promedio con medias estrellas
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.reduce((a, b) => a + b);
    return double.parse(
        (sum / ratings.length).toStringAsFixed(1)); // Redondeo a 1 decimal
  }

  // 📌 Método para crear un Book desde un snapshot de Firestore
  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<double> ratings = [];

    var dataRatings = data['ratings'];
    if (dataRatings is Map<String, dynamic>) {
      // Convertimos los valores a double en lugar de int
      ratings = dataRatings.values.map((r) => (r as num).toDouble()).toList();
    }

    return Book(
      id: doc.id,
      title: data['title'] ?? 'Título desconocido',
      author: data['author'] ?? 'Autor desconocido',
      description: data['description'] ?? 'No hay descripción disponible',
      coverUrl: data['coverUrl'],
      workKey: data['workKey'],
      ratings: ratings,
      rating: ratings.isNotEmpty
          ? double.parse((ratings.reduce((a, b) => a + b) / ratings.length)
              .toStringAsFixed(1))
          : 0.0, // Redondeo a 1 decimal
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

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['workKey']?.substring(7) ?? '',
      title: json['title'] ?? 'Título desconocido',
      author: json['author'] ?? 'Autor desconocido',
      description: json['description'],
      rating: json['rating'] ?? 0,
      coverUrl: json['cover'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover']}-L.jpg'
          : null,
      workKey: json['workKey'], // Agregar al constructor
    );
  }
}
