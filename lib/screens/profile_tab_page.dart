import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/models/profile.dart';
import 'package:vista/providers.dart';
import 'package:vista/utility/colors_app.dart';

/// Tab profilo: riepilogo account e uscita.
class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  static const _monthsIt = [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];

  static String _formatJoined(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day} ${_monthsIt[d.month - 1]} ${d.year}';
  }

  static String _avatarLetter(String displayName, String email) {
    final n = displayName.trim();
    if (n.isNotEmpty) return n.substring(0, 1).toUpperCase();
    final e = email.trim();
    if (e.isNotEmpty) return e.substring(0, 1).toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(profileProvider);
    final sessionEmail =
        Supabase.instance.client.auth.currentUser?.email ?? '';
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Future<void> reloadProfile() async {
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: asyncProfile.when(
          data: (Profile? profile) {
            final email = profile?.email.isNotEmpty == true
                ? profile!.email
                : sessionEmail;
            final displayName = profile?.displayName ?? '';
            final greetingName = displayName.trim().isNotEmpty
                ? displayName.trim()
                : (email.contains('@') ? email.split('@').first : email);
            final joined = _formatJoined(profile?.createdAt);

            return RefreshIndicator(
              onRefresh: reloadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: Text('Profilo', style: textTheme.displaySmall),
                  ),
                  const SizedBox(height: 16),
                  _ProfileHeader(
                    avatarLetter: _avatarLetter(displayName, email),
                    name: 'Ciao, $greetingName',
                    email: email,
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'ACCOUNT',
                      style: textTheme.labelLarge?.copyWith(letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AccountList(
                    email: email,
                    displayName: displayName,
                    joined: joined,
                    accountId: profile?.id,
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider).signOut();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorsApp.error,
                      side: BorderSide(
                        color: ColorsApp.error.withValues(alpha: 0.4),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Esci dall\u2019account'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: ColorsApp.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Non è stato possibile caricare il profilo.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  if (sessionEmail.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Email sessione: $sessionEmail',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: reloadProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Riprova'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider).signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Esci dall\u2019account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatarLetter,
    required this.name,
    required this.email,
  });

  final String avatarLetter;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorsApp.primarySoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ColorsApp.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarLetter,
              style: const TextStyle(
                color: ColorsApp.onPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.email,
    required this.displayName,
    required this.joined,
    required this.accountId,
  });

  final String email;
  final String displayName;
  final String joined;
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _AccountRow(
        icon: Icons.email_outlined,
        label: 'Email',
        value: email.isEmpty ? '—' : email,
      ),
      _AccountRow(
        icon: Icons.badge_outlined,
        label: 'Nome visualizzato',
        value: displayName.isEmpty ? '—' : displayName,
      ),
      _AccountRow(
        icon: Icons.calendar_today_outlined,
        label: 'Iscritto dal',
        value: joined,
      ),
      if (accountId != null && accountId!.isNotEmpty)
        _AccountRow(
          icon: Icons.fingerprint_outlined,
          label: 'ID account',
          value: accountId!,
          monospace: true,
          selectable: true,
        ),
    ];

    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(const Divider(
          height: 1,
          indent: 56,
          endIndent: 16,
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorsApp.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorsApp.outline),
      ),
      child: Column(children: children),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = textTheme.bodyLarge?.copyWith(
      color: ColorsApp.onSurface,
      fontFamily: monospace ? 'monospace' : null,
      fontSize: monospace ? 13 : 16,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorsApp.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: ColorsApp.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                if (selectable)
                  SelectableText(value, style: valueStyle)
                else
                  Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
