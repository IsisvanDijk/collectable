import 'package:collectable/screens/edit_book_screen.dart';

import 'models/book.dart';
import 'screens/onboarding_loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_overview_screen.dart';
import 'screens/add_book_screen.dart';
import 'screens/export_screen.dart';

import 'package:collectable/screens/settings_screen.dart';
import 'package:collectable/screens/book_detail_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

CustomTransitionPage fadeTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/onboarding',
  refreshListenable: _AuthStateNotifier(),
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoginRoute = state.matchedLocation == '/login';
    final isOnboardingRoute = state.matchedLocation == '/onboarding';

    if (isOnboardingRoute) return null;
    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => fadeTransitionPage(
        context: context, state: state, child: const OnboardingLoadingScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => fadeTransitionPage(
        context: context, state: state, child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => fadeTransitionPage(
        context: context, state: state, child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/book/:id/edit',
      pageBuilder: (context, state) => fadeTransitionPage(
        context: context,
        state: state,
        child: EditBookScreen(book: state.extra as Book),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context, state: state, child: const HomeOverviewScreen(),
            ),
            routes: [
              GoRoute(
                path: 'book/:id',
                pageBuilder: (context, state) => fadeTransitionPage(
                  context: context,
                  state: state,
                  child: BookDetailScreen(bookId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/add',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context, state: state, child: const AddBookScreen(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/export',
            pageBuilder: (context, state) => fadeTransitionPage(
              context: context, state: state, child: const ExportScreen(),
            ),
          ),
        ]),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Collectable',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            SvgPicture.asset(
              'assets/images/Background.svg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            child!,
          ],
        );
      },
    );
  }
}

const kTextColor = Color(0xFF2C3E50);
const kButtonRed = Color(0xFF521121);

PreferredSizeWidget buildAppBar(BuildContext context,
    {required String title, bool showSettings = true, bool showBack = false, List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    leading: showBack
        ? GestureDetector(
      onTap: () => context.pop(),
      child: const Icon(Icons.arrow_back, color: kTextColor),
    )
        : null,
    automaticallyImplyLeading: false,
    title: Text(
      title,
      style: const TextStyle(
        color: kTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    titleSpacing: showBack ? 0 : 20,
    actions: actions ?? (showSettings
        ? [
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: kTextColor),
        onPressed: () => context.push('/settings'),
      ),
      const SizedBox(width: 8),
    ]
        : null),
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            border: const Border(
              top: BorderSide(color: Colors.white, width: 1.5),
              left: BorderSide(color: Colors.white, width: 1.5),
              right: BorderSide(color: Colors.white, width: 1.5),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(index),
            indicatorColor: Colors.white.withOpacity(0.4),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home, color: Color(0xFF2C3E50)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.add, color: Color(0xFF2C3E50)),
                label: 'Add',
              ),
              NavigationDestination(
                icon: Icon(Icons.file_download, color: Color(0xFF2C3E50)),
                label: 'Export',
              ),
            ],
          ),
        ),
      ),
    );
  }
}