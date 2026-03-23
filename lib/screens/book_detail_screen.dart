import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, title: 'Book Details'),
      body: Center(
        child: Text('Book ID: $bookId'),
      ),
    );
  }
}
