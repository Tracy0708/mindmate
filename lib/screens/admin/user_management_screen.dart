import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import '../../services/interactive_message_service.dart';

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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.96), const Color(0xFFFFF8E7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.fieldBorder.withOpacity(0.45)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.brownDark)),
                        SizedBox(height: 4),
                        Text('Search, add, edit and manage user accounts.', style: TextStyle(fontSize: 12, color: AppColors.brownMedium)),
                      ]),
                    ),
                    // Create User button
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.golden,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
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
                  border: Border.all(color: AppColors.fieldBorder.withOpacity(0.55)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 5))],
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
                        return const Center(child: CircularProgressIndicator(color: AppColors.golden));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.brownMedium)));
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
                              border: Border.all(color: AppColors.fieldBorder.withOpacity(0.4)),
                            ),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(_searchQuery.isEmpty ? Icons.group_off_rounded : Icons.manage_search_rounded,
                                  size: 40, color: AppColors.brownMedium),
                              const SizedBox(height: 10),
                              Text(_searchQuery.isEmpty ? 'No users found' : 'No matching users',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark)),
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
                              decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                              child: Text('${users.length} user${users.length == 1 ? '' : 's'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brownDark)),
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
          title: const Text('Create User Account', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark)),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, foregroundColor: Colors.white),
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
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
          title: const Text('Edit User', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brownDark)),
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
                  const Icon(Icons.email_outlined, color: AppColors.brownLight, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(user.userEmail, style: const TextStyle(color: AppColors.brownMedium, fontSize: 14))),
                  const Icon(Icons.lock_outline, size: 14, color: AppColors.brownLight),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, foregroundColor: Colors.white),
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
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  InputDecoration _inputDeco(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.brownLight, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.fieldBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.golden, width: 2)),
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
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.brownLight),
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

  @override
  Widget build(BuildContext context) {
    final isDisabled = user.isDisabled;
    final accentColor = isDisabled ? AppColors.errorRed : AppColors.brownDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.person_rounded, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
            Text(user.userEmail, style: const TextStyle(fontSize: 12, color: AppColors.brownMedium)),
          ])),
          _Chip(label: isDisabled ? 'Disabled' : 'Active', color: isDisabled ? AppColors.errorRed : Colors.green),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showDetail(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.fieldBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View', style: TextStyle(fontSize: 12, color: AppColors.brownDark, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.golden),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.golden),
              label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.golden, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Consumer<AdminViewModel>(
              builder: (context, vm, _) => ElevatedButton.icon(
                onPressed: () => _toggleDisable(context, vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: Icon(isDisabled ? Icons.lock_open : Icons.block, size: 16),
                label: Text(isDisabled ? 'Enable' : 'Disable', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
            tooltip: 'Delete user',
          ),
        ]),
      ]),
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
                final accentColor = isDisabled ? AppColors.errorRed : AppColors.brownDark;

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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, accentColor.withOpacity(0.06)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: accentColor.withOpacity(0.15)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor.withOpacity(0.18), accentColor.withOpacity(0.06)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, color: accentColor, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brownDark)),
                          const SizedBox(height: 3),
                          Text(user.userEmail, style: const TextStyle(fontSize: 13, color: AppColors.brownMedium)),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, children: [
                            _Chip(label: isDisabled ? 'Disabled' : 'Active', color: isDisabled ? AppColors.errorRed : Colors.green),
                            _Chip(label: user.role == 'admin' ? 'Admin' : 'User', color: AppColors.brownDark),
                          ]),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── PROFILE INFO ──
                    _sectionTitle('Profile Information'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        _infoTile(Icons.badge_outlined, 'Full Name', user.userName),
                        _divider(),
                        _infoTile(Icons.email_outlined, 'Email', user.userEmail),
                        _divider(),
                        _infoTile(Icons.fingerprint, 'User ID', user.userID, mono: true),
                        _divider(),
                        _infoTile(Icons.manage_accounts_outlined, 'Role', user.role == 'admin' ? 'Administrator' : 'Regular User'),
                        if (user.age != null) ...[
                          _divider(),
                          _infoTile(Icons.cake_outlined, 'Age', '${user.age} years old'),
                        ],
                        if (user.gender != null) ...[
                          _divider(),
                          _infoTile(Icons.people_outline, 'Gender', user.gender!),
                        ],
                        _divider(),
                        _infoTile(
                          Icons.access_time_rounded,
                          'Last Login',
                          user.lastLogin != null
                              ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} at ${user.lastLogin!.hour.toString().padLeft(2, '0')}:${user.lastLogin!.minute.toString().padLeft(2, '0')}'
                              : 'Never',
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── USAGE STATS ──
                    _sectionTitle('Usage Statistics'),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _statCard('Mood Logs', isLoading ? '—' : '${stats?['moodLogs'] ?? 0}', Icons.mood_rounded, const Color(0xFF42A5F5))),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Activities Done', isLoading ? '—' : '${stats?['completedActivities'] ?? 0}', Icons.spa_rounded, const Color(0xFF9C27B0))),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Last Active', isLoading ? '—' : _fmtDate(stats?['lastActive'] as DateTime?), Icons.calendar_today_rounded, const Color(0xFF66BB6A))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _statCard('Status', isDisabled ? 'Disabled' : 'Active', Icons.shield_outlined, isDisabled ? AppColors.errorRed : Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Type', user.role == 'admin' ? 'Admin' : 'User', Icons.person_outline, AppColors.golden)),
                    ]),
                    const SizedBox(height: 24),

                    // ── MANAGEMENT ACTIONS ──
                    _sectionTitle('Management Actions'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.fieldBorder.withOpacity(0.5)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      style: TextStyle(fontSize: 11, color: AppColors.brownLight, height: 1.5),
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

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.brownDark));

  Widget _divider() => Divider(height: 1, indent: 56, color: AppColors.fieldBorder.withOpacity(0.4));

  Widget _infoTile(IconData icon, String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.golden.withOpacity(0.10), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: AppColors.golden),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.brownMedium, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: mono ? 11 : 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDark,
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
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.brownMedium, fontWeight: FontWeight.w600)),
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
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDestructive ? AppColors.errorRed : AppColors.brownDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.brownMedium)),
          ])),
          Icon(Icons.chevron_right, color: isDestructive ? AppColors.errorRed.withOpacity(0.5) : AppColors.brownLight, size: 20),
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
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.2))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}
