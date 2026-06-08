import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/user.dart';
import 'package:progressio_desktop/providers/user_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late UserProvider _userProvider;

  final _idController = TextEditingController();
  AppUser? _user;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = context.read<UserProvider>();
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _lookupUser() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) {
      setState(() => _error = 'Please enter a valid user ID.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _user = null;
    });
    try {
      final user = await _userProvider.getProfile(id);
      setState(() => _user = user);
    } catch (e) {
      setState(() => _error = 'User not found or error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Users',
      child: Column(
        children: [
          _buildNotice(),
          const Divider(height: 1, color: AppColors.divider),
          _buildLookup(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Backend does not expose a user list endpoint. '
              'Users can be looked up individually by ID via GET /api/users/{id}/profile. '
              'A GET /api/admin/users endpoint is required for full admin listing.',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookup() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _idController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'User ID',
                prefixIcon: Icon(Icons.person_search,
                    color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _lookupUser(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _lookupUser,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Lookup User'),
          ),
          if (_error != null) ...[
            const SizedBox(width: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_user == null) {
      return const Center(
        child: Text(
          'Enter a user ID above to look up a user.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildUserCard(_user!),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(user),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('@${user.username}',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(user.email,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (user.isPremium) _badge('Premium', AppColors.premium),
                        const SizedBox(height: 4),
                        _badge(
                          user.isProfilePublic ? 'Public' : 'Private',
                          user.isProfilePublic
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                _infoRow('User ID', '#${user.id}'),
                _infoRow('Member Since', formatDate(user.createdAt)),
                _infoRow('Profile Visibility',
                    user.isProfilePublic ? 'Public' : 'Private'),
                _infoRow('Premium', user.isPremium ? 'Yes' : 'No'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(width: 64, height: 64, color: AppColors.divider),
          errorWidget: (_, __, ___) => _defaultAvatar(user),
        ),
      );
    }
    return _defaultAvatar(user);
  }

  Widget _defaultAvatar(AppUser user) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12)),
    );
  }
}