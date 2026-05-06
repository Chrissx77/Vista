import 'package:flutter/material.dart';
import 'package:vista/utility/colors_app.dart';

/// Pagina temporanea per acquisto abbonamento Premium.
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ColorsApp.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorsApp.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: ColorsApp.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vista Premium',
                    style: textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Versione in arrivo',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Questa è una pagina temporanea. Qui potrai acquistare l’abbonamento Premium quando il checkout sarà pronto.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _FeatureTile(
            icon: Icons.filter_alt_outlined,
            title: 'Filtri avanzati',
            subtitle: 'Parcheggio, WC, acqua, sosta camper e altri filtri smart.',
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.auto_graph,
            title: 'Classifiche intelligenti',
            subtitle: 'Trend e consigli personalizzati per area e preferenze.',
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.map_outlined,
            title: 'Esperienza mappa completa',
            subtitle: 'Più dettagli su percorsi, POI e servizi utili nelle vicinanze.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.shopping_cart_checkout_outlined),
              label: const Text('Acquista Premium (presto)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorsApp.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorsApp.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ColorsApp.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: ColorsApp.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
