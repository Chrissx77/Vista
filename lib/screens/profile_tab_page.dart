import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vista/models/pointview.dart';
import 'package:vista/models/profile.dart';
import 'package:vista/providers.dart';
import 'package:vista/screens/edit_point_page.dart';
import 'package:vista/screens/point_detail_page.dart';
import 'package:vista/utility/colors_app.dart';
import 'package:vista/widgets/cached_image.dart';

/// Tab profilo: account / I miei punti / Salvati.
class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final asyncProfile = ref.watch(profileProvider(currentUserId));
    final sessionEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final textTheme = Theme.of(context).textTheme;

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

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profilo', style: textTheme.displaySmall),
                      const SizedBox(height: 12),
                      _ProfileHeader(
                        avatarLetter: _avatarLetter(displayName, email),
                        name: 'Ciao, $greetingName',
                        email: email,
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: ColorsApp.primary,
                  unselectedLabelColor: ColorsApp.onSurfaceMuted,
                  indicatorColor: ColorsApp.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Account'),
                    Tab(text: 'I miei punti'),
                    Tab(text: 'Salvati'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AccountSection(profile: profile, email: email),
                      const _MyPointsSection(),
                      const _SavedPointsSection(),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace _) => _ErrorState(
            message: e.toString(),
            sessionEmail: sessionEmail,
            onReload: () async {
              ref.invalidate(profileProvider(currentUserId));
              await ref.read(profileProvider(currentUserId).future);
            },
            onSignOut: () async {
              await ref.read(authControllerProvider).signOut();
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection({required this.profile, required this.email});

  final Profile? profile;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = profile?.displayName ?? '';
    final joined = _ProfileTabPageState._formatJoined(profile?.createdAt);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isPremium = profile?.isPremium ?? false;

    Future<void> reload() async {
      ref.invalidate(profileProvider(currentUserId));
      await ref.read(profileProvider(currentUserId).future);
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Spazio extra in basso per evitare sovrapposizione con FAB centerDocked.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
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
            isPremium: isPremium,
          ),
          const SizedBox(height: 12),
          if (!isPremium)
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Upgrade Premium non ancora attivo: integrazione pagamenti in arrivo.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Attiva Premium (presto disponibile)'),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorsApp.error,
              side: BorderSide(color: ColorsApp.error.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Esci dall\u2019account'),
          ),
        ],
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
    required this.isPremium,
  });

  final String email;
  final String displayName;
  final String joined;
  final String? accountId;
  final bool isPremium;

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
      _AccountRow(
        icon: Icons.workspace_premium_outlined,
        label: 'Piano',
        value: isPremium ? 'Premium' : 'Free',
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
        children.add(const Divider(height: 1, indent: 56, endIndent: 16));
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

// ---------------------------------------------------------------------------
// I miei punti
// ---------------------------------------------------------------------------

class _MyPointsSection extends ConsumerWidget {
  const _MyPointsSection();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Pointview pv,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina punto'),
        content: Text(
          'Vuoi eliminare definitivamente "${pv.name ?? 'questo punto'}"? L\'azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: ColorsApp.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = pv.id;
    if (id == null) return;
    try {
      await ref.read(pointviewControllerProvider).delete(id);
      ref.invalidate(myPointviewsProvider);
      ref.invalidate(pointviewsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Punto eliminato.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMine = ref.watch(myPointviewsProvider);
    return asyncMine.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CenteredMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Errore di caricamento',
        subtitle: e.toString(),
      ),
      data: (List<Pointview> items) {
        if (items.isEmpty) {
          return const _CenteredMessage(
            icon: Icons.landscape_outlined,
            title: 'Nessun punto creato',
            subtitle: 'I punti che condividi appariranno qui.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myPointviewsProvider);
            await ref.read(myPointviewsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final pv = items[i];
              return _MyPointTile(
                pointview: pv,
                onTap: () {
                  if (pv.id == null) return;
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PointDetailPage(pointId: pv.id!),
                    ),
                  );
                },
                onEdit: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EditPointPage(pointview: pv),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(myPointviewsProvider);
                  }
                },
                onDelete: () => _confirmDelete(context, ref, pv),
              );
            },
          ),
        );
      },
    );
  }
}

class _MyPointTile extends StatelessWidget {
  const _MyPointTile({
    required this.pointview,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Pointview pointview;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      if ((pointview.city ?? '').trim().isNotEmpty) pointview.city!.trim(),
      if ((pointview.region ?? '').trim().isNotEmpty) pointview.region!.trim(),
    ].join(', ');

    return Material(
      color: ColorsApp.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorsApp.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: CachedImage(
                    url: pointview.imageUrls.isEmpty
                        ? null
                        : pointview.imageUrls.first,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pointview.name ?? '',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifica'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onDelete,
                          style: TextButton.styleFrom(
                            foregroundColor: ColorsApp.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Elimina'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Salvati
// ---------------------------------------------------------------------------

class _SavedPointsSection extends ConsumerWidget {
  const _SavedPointsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSaved = ref.watch(myFavoritesProvider);
    return asyncSaved.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _CenteredMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Errore di caricamento',
        subtitle: e.toString(),
      ),
      data: (List<Pointview> items) {
        if (items.isEmpty) {
          return const _CenteredMessage(
            icon: Icons.bookmark_border,
            title: 'Nessun punto salvato',
            subtitle: 'Tocca il cuore su un punto per salvarlo qui.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myFavoritesProvider);
            await ref.read(myFavoritesProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final pv = items[i];
              return _SavedPointTile(
                pointview: pv,
                onTap: () {
                  if (pv.id == null) return;
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => PointDetailPage(pointId: pv.id!),
                    ),
                  );
                },
                onUnsave: () async {
                  final id = pv.id;
                  if (id == null) return;
                  await ref.read(favoritesControllerProvider).remove(id);
                  ref.invalidate(myFavoriteIdsProvider);
                  ref.invalidate(myFavoritesProvider);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SavedPointTile extends StatelessWidget {
  const _SavedPointTile({
    required this.pointview,
    required this.onTap,
    required this.onUnsave,
  });

  final Pointview pointview;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      if ((pointview.city ?? '').trim().isNotEmpty) pointview.city!.trim(),
      if ((pointview.region ?? '').trim().isNotEmpty) pointview.region!.trim(),
    ].join(', ');

    return Material(
      color: ColorsApp.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorsApp.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: CachedImage(
                    url: pointview.imageUrls.isEmpty
                        ? null
                        : pointview.imageUrls.first,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pointview.name ?? '',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onUnsave,
                icon: const Icon(Icons.favorite, color: ColorsApp.accentRed),
                tooltip: 'Rimuovi dai preferiti',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Common
// ---------------------------------------------------------------------------

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ColorsApp.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: ColorsApp.primary, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.sessionEmail,
    required this.onReload,
    required this.onSignOut,
  });

  final String message;
  final String sessionEmail;
  final VoidCallback onReload;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
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
              message,
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
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Esci dall\u2019account'),
            ),
            if (kDebugMode) const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
