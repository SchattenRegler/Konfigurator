import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'oss_licenses.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final Future<String> _appLicenseFuture;
  late final Future<String> _privacyPolicyFuture;
  final List<Package> _packages = List<Package>.from(allDependencies)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  static final Uri _imprintEmailUri = Uri(
    scheme: 'mailto',
    path: 'info@staerium.com',
  );
  static final Uri _esriAttributionUri =
      Uri.parse('https://www.esri.com/en-us/legal/terms/data-attributions');
  static final Uri _esriServicesUri =
      Uri.parse('https://www.esri.com/en-us/legal/terms/services');
  static final Uri _osmCopyrightUri =
      Uri.parse('https://www.openstreetmap.org/copyright');
  static final Uri _nominatimPolicyUri =
      Uri.parse('https://operations.osmfoundation.org/policies/nominatim/');

  @override
  void initState() {
    super.initState();
    _appLicenseFuture = rootBundle.loadString('LICENSE.txt');
    _privacyPolicyFuture = rootBundle.loadString('Datenschutz.txt');
  }

  Future<void> _openUri(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link konnte nicht geöffnet werden: ${uri.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechtliches'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocumentSection(
            title: 'App-Lizenz (MIT)',
            future: _appLicenseFuture,
            errorLabel: 'Lizenztext',
          ),
          const SizedBox(height: 16),
          _buildDocumentSection(
            title: 'Datenschutzerklärung',
            future: _privacyPolicyFuture,
            errorLabel: 'Datenschutzerklärung',
          ),
          const SizedBox(height: 16),
          _buildImprintSection(),
          const SizedBox(height: 16),
          _buildAttributionsSection(),
          const SizedBox(height: 16),
          _buildThirdPartySection(),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required Future<String> future,
    required String errorLabel,
  }) {
    return _buildSection(
      title: title,
      child: FutureBuilder<String>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text(
              '$errorLabel konnte nicht geladen werden: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            );
          }
          final text = snapshot.data ?? '';
          return SelectableText(text);
        },
      ),
    );
  }

  Widget _buildAttributionsSection() {
    return _buildSection(
      title: 'Verpflichtende Attributionen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Die Karten- und Suchfunktionen verwenden folgende Dienste. '
            'Bitte beachten Sie die jeweiligen Nutzungsbedingungen.',
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Imagery: Esri World Imagery — © Esri, Maxar, '
              'Earthstar Geographics, and the GIS User Community',
            ),
            subtitle: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _openUri(_esriAttributionUri),
                  child: const Text('Esri Data Attribution Terms'),
                ),
                TextButton(
                  onPressed: () => _openUri(_esriServicesUri),
                  child: const Text('Esri Services Terms'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Suche & Geokodierung: Nominatim (OpenStreetMap) — '
              '© OpenStreetMap contributors',
            ),
            subtitle: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _openUri(_osmCopyrightUri),
                  child: const Text('OpenStreetMap-Copyright'),
                ),
                TextButton(
                  onPressed: () => _openUri(_nominatimPolicyUri),
                  child: const Text('Nominatim Terms of Use'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartySection() {
    return _buildSection(
      title: 'Drittanbieter-Lizenzen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diese Anwendung verwendet Open-Source-Komponenten. '
            'Die jeweiligen Lizenztexte finden Sie in den folgenden Abschnitten.',
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final package = _packages[index];
              return _PackageLicenseTile(
                package: package,
                onOpenLink: _openUri,
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _packages.length,
          ),
        ],
      ),
    );
  }

  Widget _buildImprintSection() {
    return _buildSection(
      title: 'Impressum',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Herausgeber & verantwortlich für den Inhalt:\n'
            'Eric Städler\n'
            'Guschstrasse 59\n'
            '8610 Uster\n'
            'Schweiz',
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('info@staerium.com'),
            subtitle: const Text('Kontakt per E-Mail'),
            onTap: () => _openUri(_imprintEmailUri),
          ),
        ],
      ),
    );
  }
}

class _PackageLicenseTile extends StatelessWidget {
  const _PackageLicenseTile({
    required this.package,
    required this.onOpenLink,
  });

  final Package package;
  final ValueChanged<Uri> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final version = package.version != null ? ' ${package.version}' : '';
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('${package.name}$version'),
      subtitle:
          package.description.isNotEmpty ? Text(package.description) : null,
      children: [
        if ((package.repository ?? package.homepage) != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                if (package.repository != null && package.repository!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => onOpenLink(Uri.parse(package.repository!)),
                    icon: const Icon(Icons.launch, size: 16),
                    label: const Text('Repository'),
                  ),
                if (package.homepage != null && package.homepage!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => onOpenLink(Uri.parse(package.homepage!)),
                    icon: const Icon(Icons.public, size: 16),
                    label: const Text('Homepage'),
                  ),
              ],
            ),
          ),
        if (package.license != null && package.license!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              package.license!,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Kein Lizenztext verfügbar.'),
          ),
      ],
    );
  }
}
