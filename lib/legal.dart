import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vista/utility/colors_app.dart';

/// Termini d'uso (EULA standard Apple — adatto a UGC finché non hai termini propri).
const String kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Privacy Policy: pagina in-app. Prima dello store hosting sostituisci con URL pubblico.
Future<void> openTermsOfUse() async {
  final uri = Uri.parse(kTermsOfUseUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void openPrivacyPolicy(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
  );
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text('Vista — Informativa sulla privacy', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Ultimo aggiornamento: settembre 2026',
            style: textTheme.bodySmall?.copyWith(color: ColorsApp.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
          Text(
            'Questa informativa descrive come l’app Vista tratta i dati personali '
            'quando usi i nostri servizi (Flutter + Supabase).',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _section(
            textTheme,
            'Titolare',
            'Il titolare del trattamento è il soggetto che pubblica Vista sugli store. '
            'Per richieste privacy contatta il supporto indicato nella scheda dello store.',
          ),
          _section(
            textTheme,
            'Dati che trattiamo',
            '• Account: email e password (gestite da Supabase Auth).\n'
            '• Profilo: nome visualizzato e metadati account.\n'
            '• Contenuti UGC: punti panoramici, descrizioni, foto, coordinate, preferiti, recensioni e segnalazioni.\n'
            '• Posizione: solo se concedi il permesso (es. creazione punto, recensione geofenced).\n'
            '• Dati tecnici: token di sessione e log necessari al funzionamento del servizio.',
          ),
          _section(
            textTheme,
            'Finalità',
            'Fornire l’account, pubblicare e mostrare i punti panoramici, gestire preferiti '
            'e moderazione, garantire sicurezza e conformità agli store.',
          ),
          _section(
            textTheme,
            'Base giuridica',
            'Esecuzione del contratto (uso dell’app), consenso dove richiesto '
            '(es. accesso a fotocamera/galleria/posizione) e legittimo interesse '
            'alla sicurezza e alla moderazione dei contenuti.',
          ),
          _section(
            textTheme,
            'Conservazione e cancellazione',
            'I dati restano finché l’account è attivo. Puoi eliminare l’account '
            'dalla sezione Profilo: verranno rimossi i tuoi punti, preferiti e '
            'l’utenza Auth, nei limiti tecnici del servizio.',
          ),
          _section(
            textTheme,
            'Condivisione',
            'I contenuti che pubblichi (punti, foto, testi) sono visibili agli altri utenti. '
            'I dati sono elaborati tramite Supabase (hosting EU/US a seconda del progetto). '
            'Non vendiamo i tuoi dati personali.',
          ),
          _section(
            textTheme,
            'Diritti',
            'Puoi chiedere accesso, rettifica, portabilità o cancellazione dei dati '
            'personali, e revocare i permessi di sistema dalle impostazioni del dispositivo.',
          ),
          _section(
            textTheme,
            'Minori',
            'Vista non è destinata a minori di 13 anni (o età minima richiesta nella tua giurisdizione).',
          ),
        ],
      ),
    );
  }

  static Widget _section(TextTheme textTheme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
