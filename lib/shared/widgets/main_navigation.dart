import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/views/home_tab.dart';
import '../../features/profile/presentation/views/profile_tab.dart';
import '../../core/di/injection_container.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  void _loadDocuments() {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      ref.read(documentViewModelProvider.notifier).loadDocuments(user.uid);
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
    // Listen for errors/success
    ref.listen(documentViewModelProvider, (previous, next) {
      if (next.failure != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.failure!.message), backgroundColor: AppColors.error));
        ref.read(documentViewModelProvider.notifier).clearMessages();
      }
      if (next.successMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success));
        ref.read(documentViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('e-Signature'),
        centerTitle: true,
        elevation: 0,
        actions: [if (_currentIndex == 0) IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDocuments)],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(onUploadPressed: _onUploadPressed, onRefresh: _loadDocuments),
          const _UploadTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _onUploadPressed();
          } else {
            setState(() => _currentIndex = index);
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

class _UploadTab extends StatelessWidget {
  const _UploadTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 80, color: AppColors.primary),
          SizedBox(height: 16),
          Text('Tap Upload to select a document', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
