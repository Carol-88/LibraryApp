import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:library_app/app_styles.dart';
import 'package:library_app/services/user_service.dart';
import 'package:library_app/widgets/books_list.dart';

class UserScreen extends StatefulWidget {
  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = _userService.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              "Perfil",
              style: GoogleFonts.lexend().copyWith(color: AppColors.accent),
            ),
          ),
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.accent),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: AppColors.primary),
              onPressed: () async {
                await _userService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            indicatorColor: AppColors.dark,
            tabs: [
              Tab(text: 'Favoritos'),
              Tab(text: 'Pendientes'),
              Tab(text: 'Leídos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BookListWidget(userId: user.uid, listName: 'favoritos'),
            BookListWidget(userId: user.uid, listName: 'pendientes'),
            BookListWidget(userId: user.uid, listName: 'leidos'),
          ],
        ),
      ),
    );
  }
}
