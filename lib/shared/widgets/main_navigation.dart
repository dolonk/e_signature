import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/views/home_tab.dart';
import '../../features/profile/presentation/views/profile_tab.dart';
import '../../core/di/injection_container.dart';
import '../../route/route_name.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  bool _hasLoadedHome = false;

  @override
  void initState() {
    super.initState();
  }

  void _loadHomeDocuments() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      ref.read(homeViewModelProvider.notifier).loadDocuments(user.uid);
    }
  }

  void _onUploadPressed() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      ref.read(documentViewModelProvider.notifier).pickAndUploadDocument(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch home repository - when ready, load documents for home list
    final homeRepoState = ref.watch(homeRepositoryProvider);
    homeRepoState.whenData((_) {
      if (!_hasLoadedHome) {
        _hasLoadedHome = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadHomeDocuments();
        });
      }
    });

    // Listen for document upload success and navigate to editor
    ref.listen(documentViewModelProvider, (previous, next) {
      if (next.failure != null && !next.failure!.message.contains('not initialized')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.failure!.message), backgroundColor: AppColors.error));
        ref.read(documentViewModelProvider.notifier).clearMessages();
      }

      // Handle success message
      if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success));
        ref.read(documentViewModelProvider.notifier).clearMessages();
      }

      // Navigate to editor after new upload and refresh home list
      if (next.lastUploadedDocument != null && previous?.lastUploadedDocument != next.lastUploadedDocument) {
        final document = next.lastUploadedDocument!;
        ref.read(documentViewModelProvider.notifier).clearLastUploadedDocument();

        // Refresh home list after upload
        _loadHomeDocuments();

        // Navigate to editor
        Navigator.pushNamed(context, RouteName.editor, arguments: document);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_currentIndex == 0 ? 'My Documents' : 'Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [if (_currentIndex == 0) IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHomeDocuments)],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(onUploadPressed: _onUploadPressed, onRefresh: _loadHomeDocuments),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _onUploadPressed();
          } else if (index == 0) {
            setState(() => _currentIndex = 0);
          } else if (index == 2) {
            setState(() => _currentIndex = 1);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Upload',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
