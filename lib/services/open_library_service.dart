import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenLibraryService {
  final String baseUrl = 'https://openlibrary.org';

  Future<List<Map<String, dynamic>>> searchBooks({
    String? query,
    String? title,
    String? author,
    String? genre,
  }) async {
    // Construcción dinámica de parámetros
    final queryParameters = <String, String>{};
    if (query != null && query.isNotEmpty) queryParameters['q'] = query;
    if (title != null && title.isNotEmpty) queryParameters['title'] = title;
    if (author != null && author.isNotEmpty) queryParameters['author'] = author;
    if (genre != null && genre.isNotEmpty) queryParameters['subject'] = genre;

    // Construcción de la URL con parámetros
    final url = Uri.parse('$baseUrl/search.json')
        .replace(queryParameters: queryParameters);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final books = data['docs'] as List;
        return books.map((book) {
          return {
            'title': book['title'] ?? 'Título desconocido',
            'author': (book['author_name'] as List?)?.join(', ') ??
                'Autor desconocido',
            'cover': book['cover_i'],
            'workKey': book['key'],
          };
        }).toList();
      } else {
        throw Exception(
            'Error al buscar libros: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error al realizar la búsqueda: $e');
    }
  }

  Future<Map<String, dynamic>> fetchBookDetails(String workKey) async {
    final url = Uri.parse('$baseUrl$workKey.json');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final description = data['description'];

        return {
          'description': description is String
              ? description
              : description?['value'] ?? 'No hay descripción disponible.',
        };
      } else {
        throw Exception(
            'Error al obtener los detalles del libro: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error al realizar la consulta de detalles: $e');
    }
  }
}
