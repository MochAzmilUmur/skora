import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/core/services/theme_service.dart';
import 'package:skora/core/widgets/user_avatar.dart';
import 'package:skora/core/utils/app_toast.dart';
import 'package:skora/features/profile/data/datasources/user_remote_datasource.dart';
import 'package:skora/features/profile/presentation/providers/profile_notifier.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final ProfileNotifier _notifier;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _notifier = ProfileNotifier(UserRemoteDataSource())..load();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _notifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final user = _notifier.user;
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1628),
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: const Color(0xFF64748B),
              tabs: const [
                Tab(text: 'Informasi'),
                Tab(text: 'Keamanan'),
              ],
            ),
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator(color: Colors.blue))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _InfoTab(notifier: _notifier),
                    _SecurityTab(notifier: _notifier),
                  ],
                ),
        );
      },
    );
  }
}

// ─── Info Tab ───────────────────────────────────────────────────────────────

class _InfoTab extends StatefulWidget {
  final ProfileNotifier notifier;
  const _InfoTab({required this.notifier});

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  @override
  Widget build(BuildContext context) {
    final user = widget.notifier.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          UserAvatar(
            avatarUrl: user?.avatarUrl,
            name: user?.nama ?? '',
            radius: 40,
            isUploading: widget.notifier.uploadingAvatar,
            onUpload: (file) => widget.notifier.uploadAvatar(file),
          ),
          const SizedBox(height: 12),
          if (user != null) ...[
            Text(
              user.nama,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _RoleChip(role: user.role),
          ],
          const SizedBox(height: 24),

          // Profile fields — read-only, hanya admin yang bisa ubah via web panel
          _SectionCard(
            title: 'Data Pribadi',
            children: [
              _ReadonlyField(
                label: 'Nama Lengkap',
                value: user?.nama ?? '-',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _ReadonlyField(
                label: 'Email',
                value: user?.email ?? '-',
                icon: Icons.email_outlined,
              ),
              if (user != null) ...[
                const SizedBox(height: 12),
                _ReadonlyField(
                  label: 'Bergabung',
                  value: user.createdAt != null
                      ? _formatDate(user.createdAt!)
                      : '-',
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Dark mode toggle
          _SectionCard(
            title: 'Tampilan',
            children: [
              _DarkModeToggle(),
            ],
          ),

          const SizedBox(height: 24),
          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('Yakin ingin keluar?',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await AuthStorageService.clearUser();
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Security Tab ────────────────────────────────────────────────────────────

class _SecurityTab extends StatefulWidget {
  final ProfileNotifier notifier;
  const _SecurityTab({required this.notifier});

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.notifier.changePassword(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      AppToast.showSuccess(context, widget.notifier.successMessage);
    } else {
      AppToast.showError(context, widget.notifier.error);
    }
    widget.notifier.clearStatus();
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.notifier.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: _SectionCard(
          title: 'Ubah Password',
          children: [
            _PasswordField(
              label: 'Password Saat Ini',
              controller: _oldCtrl,
              obscure: !_showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              label: 'Password Baru',
              controller: _newCtrl,
              obscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (v.length < 6) return 'Minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _PasswordField(
              label: 'Konfirmasi Password Baru',
              controller: _confirmCtrl,
              obscure: !_showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v != _newCtrl.text) return 'Password tidak cocok';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Ubah Password'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Syarat password:',
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12)),
                  const SizedBox(height: 6),
                  ...[
                    'Minimal 6 karakter',
                    'Kombinasi huruf dan angka disarankan',
                    'Jangan gunakan informasi pribadi',
                  ].map((tip) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.blue, size: 14),
                            const SizedBox(width: 6),
                            Text(tip,
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dark mode toggle ────────────────────────────────────────────────────────

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    return Row(
      children: [
        Icon(
          notifier.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          color: notifier.isDark ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notifier.isDark ? 'Mode Malam' : 'Mode Terang',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                notifier.isDark
                    ? 'Tampilan gelap — lebih nyaman di malam hari'
                    : 'Tampilan terang — lebih jelas di siang hari',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: notifier.isDark,
          onChanged: (v) => context.read<ThemeNotifier>().setDark(v),
          activeColor: Colors.blue,
          activeTrackColor: Colors.blue.withValues(alpha: 0.3),
          inactiveThumbColor: const Color(0xFFF59E0B),
          inactiveTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAsesor = role == 'asesor';
    final color = isAsesor ? Colors.orange : Colors.blue;
    final label = isAsesor ? 'Asesor' : 'Peserta';
    final icon = isAsesor ? Icons.admin_panel_settings_outlined : Icons.school_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadonlyField(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: const Icon(Icons.lock_outline,
            color: Color(0xFF64748B), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
