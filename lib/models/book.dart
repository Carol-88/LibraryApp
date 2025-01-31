class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final double rating;
  final String? coverUrl;
  final String? workKey; // Nuevo campo

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.rating = 0.0,
    this.coverUrl,
    this.workKey, // Nuevo parámetro
  });

  // Método para crear un Book desde un JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Título desconocido',
      author: json['author'] ?? 'Autor desconocido',
      description: json['description'],
      rating: json['rating'] ?? 0.0,
      coverUrl: json['cover'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover']}-S.jpg'
          : null,
      workKey: json['workKey'], // Agregar al constructor
    );
  }

  // Método para convertir un Book a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'rating': rating,
      'cover': coverUrl,
      'workKey': workKey, // Agregar al JSON
    };
  }
}
