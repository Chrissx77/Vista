import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/models/profile.dart';
import 'package:vista/providers.dart';

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
    final scheme = theme.colorScheme;

    Future<void> reloadProfile() async {
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: asyncProfile.when(
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Text(
                        _avatarLetter(displayName, email),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ciao, $greetingName',
                            style: textTheme.titleMedium,
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Account',
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.email_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Email',
                          style: textTheme.labelLarge,
                        ),
                        subtitle: Text(
                          email.isEmpty ? '—' : email,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.badge_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Nome visualizzato',
                          style: textTheme.labelLarge,
                        ),
                        subtitle: Text(
                          displayName.isEmpty ? '—' : displayName,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.calendar_today_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Iscritto dal',
                          style: textTheme.labelLarge,
                        ),
                        subtitle: Text(
                          joined,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      if (profile?.id.isNotEmpty == true) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.fingerprint_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            'ID account',
                            style: textTheme.labelLarge,
                          ),
                          subtitle: SelectableText(
                            profile!.id,
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Esci dall’account'),
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
                Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  'Non è stato possibile caricare il profilo.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                FilledButton.tonalIcon(
                  onPressed: reloadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Esci dall’account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
