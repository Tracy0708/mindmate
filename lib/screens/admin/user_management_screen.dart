import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';
import '../../widgets/app_screen_header.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBF2), Color(0xFFFFF6E6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Header — standardized AppScreenHeader with a compact "Add User" action.
            AppScreenHeader(
              title: 'User Management',
              subtitle: 'Search, add, edit and manage user accounts.',
              icon: Icons.people_rounded,
              trailing: Tooltip(
                message: 'Add User',
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showCreateUserDialog(context),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(Icons.person_add_alt_1_rounded,
                            color: AppColors.textDark, size: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.55)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or UID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: Consumer<AdminViewModel>(
                builder: (context, vm, _) {
                  return StreamBuilder<List<UserModel>>(
                    stream: vm.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.textMedium)));
                      }

                      // Filter out admin accounts, then apply search
                      final allUsers = (snapshot.data ?? []).where((u) => u.role != 'admin').toList();
                      final users = allUsers.where((u) {
                        if (_searchQuery.isEmpty) return true;
                        return u.userName.toLowerCase().contains(_searchQuery) ||
                            u.userEmail.toLowerCase().contains(_searchQuery) ||
                            u.userID.toLowerCase().contains(_searchQuery);
                      }).toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.4)),
                            ),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(_searchQuery.isEmpty ? Icons.group_off_rounded : Icons.manage_search_rounded,
                                  size: 40, color: AppColors.textMedium),
                              const SizedBox(height: 10),
                              Text(_searchQuery.isEmpty ? 'No users found' : 'No matching users',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                            ]),
                          ),
                        );
                      }

                      return Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                              child: Text('${users.length} user${users.length == 1 ? '' : 's'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                            ),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: users.length,
                            itemBuilder: (context, i) => _UserCard(
                              user: users[i],
                              onDelete: () => _confirmDelete(context, vm, users[i]),
                              onEdit: () => _showEditUserDialog(context, vm, users[i]),
                            ),
                          ),
                        ),
                      ]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminViewModel vm, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete User?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete ${user.userName}?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () { vm.deleteUser(user.userID); Navigator.pop(ctx); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Create User Dialog ──
  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String? gender;
    bool saving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: const Text('Create User Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _field('Full Name', nameCtrl, hint: 'e.g. Jane Doe', icon: Icons.person_outline),
              const SizedBox(height: 12),
              _field('Email', emailCtrl, hint: 'user@email.com', icon: Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _obscureField('Password', passCtrl, obscure, () => setState(() => obscure = !obscure)),
              const SizedBox(height: 12),
              _field('Age (optional)', ageCtrl, hint: 'e.g. 25', icon: Icons.cake_outlined, type: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: gender,
                hint: const Text('Gender (optional)'),
                decoration: _inputDeco(Icons.people_outline),
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => gender = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textDark),
              onPressed: saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                  InteractiveMessageService.showError(context, title: 'Missing fields', message: 'Name, email and password are required.');
                  return;
                }
                setState(() => saving = true);
                try {
                  await Provider.of<AdminViewModel>(context, listen: false).createUser(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    age: int.tryParse(ageCtrl.text.trim()),
                    gender: gender,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    InteractiveMessageService.showSuccess(context,
                        title: 'User created ✅',
                        message: 'Account for ${nameCtrl.text.trim()} has been created.');
                  }
                } catch (e) {
                  setState(() => saving = false);
                  if (context.mounted) {
                    InteractiveMessageService.showError(context, title: 'Failed to create user', message: e.toString());
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Create', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit User Dialog ──
  void _showEditUserDialog(BuildContext context, AdminViewModel vm, UserModel user) {
    final nameCtrl = TextEditingController(text: user.userName);
    final ageCtrl = TextEditingController(text: user.age != null ? '${user.age}' : '');
    String? gender = user.gender;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: const Text('Edit User', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _field('Full Name', nameCtrl, hint: user.userName, icon: Icons.person_outline),
              const SizedBox(height: 12),
              // Email shown as read-only
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.email_outlined, color: AppColors.textLight, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(user.userEmail, style: const TextStyle(color: AppColors.textMedium, fontSize: 14))),
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.textLight),
                ]),
              ),
              const SizedBox(height: 12),
              _field('Age (optional)', ageCtrl, hint: 'e.g. 25', icon: Icons.cake_outlined, type: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: gender,
                hint: const Text('Gender (optional)'),
                decoration: _inputDeco(Icons.people_outline),
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => gender = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textDark),
              onPressed: saving ? null : () async {
                setState(() => saving = true);
                try {
                  await vm.updateUserProfile(user.userID,
                      name: nameCtrl.text.trim(),
                      age: int.tryParse(ageCtrl.text.trim()),
                      gender: gender);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    InteractiveMessageService.showSuccess(context,
                        title: 'User updated ✅', message: '${nameCtrl.text.trim()}\'s profile has been updated.');
                  }
                } catch (e) {
                  setState(() => saving = false);
                  if (context.mounted) {
                    InteractiveMessageService.showError(context, title: 'Update failed', message: e.toString());
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  InputDecoration _inputDeco(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _field(String label, TextEditingController ctrl, {String hint = '', IconData icon = Icons.edit, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: _inputDeco(icon).copyWith(hintText: hint, labelText: label),
    );
  }

  Widget _obscureField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: _inputDeco(Icons.lock_outline).copyWith(
        labelText: label,
        hintText: 'Min. 6 characters',
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textLight),
          onPressed: toggle,
        ),
      ),
    );
  }
}

// ── User Card ──
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _UserCard({required this.user, required this.onDelete, required this.onEdit});

  static const _cardAccent = Color(0xFFF9A825); // amber — consistent across all cards

  String get _initials {
    final parts = user.userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.userName.isEmpty ? '?' : user.userName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = user.isDisabled;
    final avatarColor = isDisabled ? AppColors.errorRed : _cardAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: avatarColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: avatarColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Initials avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor, avatarColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: avatarColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(
                  child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.userName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.userEmail,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    overflow: TextOverflow.ellipsis),
              ])),
              const SizedBox(width: 8),
              _Chip(label: isDisabled ? 'Disabled' : 'Active', color: isDisabled ? AppColors.errorRed : const Color(0xFF43A047)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetail(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: BorderSide(color: avatarColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: avatarColor.withValues(alpha: 0.05),
                  ),
                  icon: Icon(Icons.visibility_rounded, size: 15, color: avatarColor),
                  label: Text('View', style: TextStyle(fontSize: 12, color: avatarColor, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    side: const BorderSide(color: Color(0xFFF9A825)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFFF9A825).withValues(alpha: 0.06),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFFF9A825)),
                  label: const Text('Edit', style: TextStyle(fontSize: 12, color: Color(0xFFF9A825), fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Consumer<AdminViewModel>(
                  builder: (context, vm, _) {
                    final btnColor = isDisabled ? const Color(0xFF43A047) : const Color(0xFFFF7043);
                    return ElevatedButton.icon(
                      onPressed: () => _toggleDisable(context, vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(isDisabled ? Icons.lock_open_rounded : Icons.block_rounded, size: 15),
                      label: Text(isDisabled ? 'Enable' : 'Disable', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                tooltip: 'Delete user',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ]),
          ]),
        ),
    );
  }

  void _toggleDisable(BuildContext context, AdminViewModel vm) async {
    await vm.setUserDisabled(user.userID, !user.isDisabled);
    if (context.mounted) {
      InteractiveMessageService.showSuccess(context,
          title: user.isDisabled ? 'Account enabled' : 'Account disabled',
          message: user.isDisabled ? 'User can log in again.' : 'User is blocked from logging in.');
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.97,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Consumer<AdminViewModel>(
            builder: (context, vm, _) => FutureBuilder<Map<String, dynamic>>(
              future: vm.getUserUsageStats(user.userID),
              builder: (context, snapshot) {
                final stats = snapshot.data;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final isDisabled = user.isDisabled;

                final avatarInitials = () {
                  final parts = user.userName.trim().split(' ');
                  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                  return user.userName.isEmpty ? '?' : user.userName[0].toUpperCase();
                }();

                final headerGradient = isDisabled
                    ? const [Color(0xFFC62828), Color(0xFFE53935)]
                    : const [Color(0xFF3949AB), Color(0xFF7B1FA2)];
                final headerShadowColor = isDisabled ? const Color(0xFFC62828) : const Color(0xFF3949AB);

                return ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 44, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // ── HEADER CARD ──
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: headerGradient,
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: headerShadowColor.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
                          BoxShadow(color: headerShadowColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2.5),
                          ),
                          child: Center(
                            child: Text(avatarInitials,
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.userName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.email_outlined, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(user.userEmail,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 6, children: [
                            _DetailChip(
                              label: isDisabled ? 'Disabled' : 'Active',
                              icon: isDisabled ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                              bgColor: isDisabled ? Colors.red.shade800 : const Color(0xFF2E7D32),
                            ),
                            _DetailChip(
                              label: user.role == 'admin' ? 'Admin' : 'User',
                              icon: user.role == 'admin' ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                              bgColor: Colors.white.withValues(alpha: 0.2),
                            ),
                          ]),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 22),

                    // ── PROFILE INFO ──
                    _sectionTitle('Profile Information'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        _infoTile(Icons.badge_outlined, 'Full Name', user.userName, color: const Color(0xFF3949AB)),
                        _divider(),
                        _infoTile(Icons.email_outlined, 'Email', user.userEmail, color: const Color(0xFFF57C00)),
                        _divider(),
                        _infoTile(Icons.fingerprint, 'User ID', user.userID, mono: true, color: const Color(0xFF7B1FA2)),
                        _divider(),
                        _infoTile(Icons.manage_accounts_outlined, 'Role',
                            user.role == 'admin' ? 'Administrator' : 'Regular User',
                            color: const Color(0xFF00796B)),
                        if (user.age != null) ...[
                          _divider(),
                          _infoTile(Icons.cake_outlined, 'Age', '${user.age} years old', color: const Color(0xFFE91E63)),
                        ],
                        if (user.gender != null) ...[
                          _divider(),
                          _infoTile(Icons.people_outline, 'Gender', user.gender!, color: const Color(0xFF6200EE)),
                        ],
                        _divider(),
                        _infoTile(
                          Icons.access_time_rounded,
                          'Last Login',
                          user.lastLogin != null
                              ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} at ${user.lastLogin!.hour.toString().padLeft(2, '0')}:${user.lastLogin!.minute.toString().padLeft(2, '0')}'
                              : 'Never',
                          color: const Color(0xFF2E7D32),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 22),

                    // ── USAGE STATS — consistent 2×2 grid ──
                    _sectionTitle('Usage Statistics'),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: _statCard('Mood Logs', isLoading ? '—' : '${stats?['moodLogs'] ?? 0}', Icons.mood_rounded, const Color(0xFF3949AB))),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Activities', isLoading ? '—' : '${stats?['completedActivities'] ?? 0}', Icons.spa_rounded, const Color(0xFF7B1FA2))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(child: _statCard('Last Active', isLoading ? '—' : _fmtDate(stats?['lastActive'] as DateTime?), Icons.calendar_today_rounded, const Color(0xFF00796B))),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Account', isDisabled ? 'Disabled' : 'Active', Icons.shield_rounded, isDisabled ? AppColors.errorRed : const Color(0xFF2E7D32))),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── MANAGEMENT ACTIONS ──
                    _sectionTitle('Management Actions'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        // Reset Password
                        _actionTile(
                          icon: Icons.lock_reset_rounded,
                          iconColor: const Color(0xFF42A5F5),
                          label: 'Send Password Reset Link',
                          subtitle: 'Email a reset link to ${user.userEmail}',
                          onTap: () async {
                            await vm.resetPasswordForEmail(user.userEmail);
                            if (ctx.mounted) {
                              InteractiveMessageService.showSuccess(ctx,
                                  title: 'Reset link sent ✉️',
                                  message: 'Password reset email sent to ${user.userEmail}');
                            }
                          },
                        ),
                        _divider(),
                        // Enable / Disable
                        _actionTile(
                          icon: isDisabled ? Icons.lock_open_rounded : Icons.block_rounded,
                          iconColor: isDisabled ? Colors.green : Colors.orange,
                          label: isDisabled ? 'Enable Account' : 'Disable Account',
                          subtitle: isDisabled
                              ? 'Allow this user to log in again'
                              : 'Block this user from logging in',
                          onTap: () async {
                            await vm.setUserDisabled(user.userID, !isDisabled);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              InteractiveMessageService.showSuccess(ctx,
                                  title: isDisabled ? 'Account enabled' : 'Account disabled',
                                  message: isDisabled ? 'User can log in again.' : 'User is blocked from logging in.');
                            }
                          },
                        ),
                        _divider(),
                        // Delete
                        _actionTile(
                          icon: Icons.delete_forever_rounded,
                          iconColor: AppColors.errorRed,
                          label: 'Delete Account',
                          subtitle: 'Permanently remove this user\'s profile',
                          isDestructive: true,
                          onTap: () {
                            Navigator.pop(ctx);
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                title: const Text('Delete User?', style: TextStyle(fontWeight: FontWeight.w700)),
                                content: Text('Permanently delete ${user.userName}?\nThis cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                                    onPressed: () { vm.deleteUser(user.userID); Navigator.pop(c); },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Password resets are sent via Firebase Auth. Disable/enable is enforced through the Firestore user record.',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.5),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Row(
    children: [
      Container(
        width: 4, height: 18,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    ],
  );

  Widget _divider() => Divider(height: 1, indent: 56, color: AppColors.fieldBorder.withValues(alpha: 0.4));

  Widget _infoTile(IconData icon, String label, String value, {bool mono = false, Color color = AppColors.primary}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700, letterSpacing: 0.2)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: mono ? 11 : 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontFamily: mono ? 'monospace' : null),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.35), shape: BoxShape.circle),
          ),
        ]),
        const SizedBox(height: 14),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDestructive ? AppColors.errorRed : AppColors.textDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
          ])),
          Icon(Icons.chevron_right_rounded,
              color: isDestructive ? AppColors.errorRed.withValues(alpha: 0.5) : AppColors.textLight, size: 20),
        ]),
      ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return 'N/A';
    return '${d.day}/${d.month}/${d.year}';
  }
}


class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  const _DetailChip({required this.label, required this.icon, required this.bgColor});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      );
}
