import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ProfileViewModel>(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final settings = vm.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: settings == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Receive daily reminders and prompts'),
                value: settings.notificationEnabled,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  vm.toggleNotifications(val);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle app appearance'),
                value: themeVM.isDarkMode,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  themeVM.toggleDarkMode(val);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(settings.language == 'en' ? 'English' : settings.language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Dialog to select language
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Privacy Center'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                title: const Text('Log out', style: TextStyle(color: Colors.red)),
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
              )
            ],
          ),
    );
  }
}
