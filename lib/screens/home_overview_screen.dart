import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../repositories/book_repository.dart';
import '../models/book.dart';
import '../main.dart';

class HomeOverviewScreen extends StatelessWidget {
  const HomeOverviewScreen({super.key});

  String get username {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    return (name != null && name.isNotEmpty) ? name : 'there';
  }

  @override
  Widget build(BuildContext context) {
    final bookRepo = BookRepository();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: buildAppBar(context, title: 'Hello, $username!'),
      body: StreamBuilder<List<Book>>(
        stream: bookRepo.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Empty-shelf.png',
                    width: 220,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your collection is empty',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start by adding your first book!',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title, style: const TextStyle(color: kTextColor)),
                subtitle: Text('${book.author} - ${book.condition.name}',
                    style: const TextStyle(color: kTextColor)),
                trailing: book.photoUrls.isNotEmpty
                    ? Image.network(book.photoUrls.first,
                    width: 50, height: 50, fit: BoxFit.cover)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}