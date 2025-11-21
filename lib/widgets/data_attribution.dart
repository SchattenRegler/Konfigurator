import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/esri_attribution_service.dart';

class PoweredByNominatimNote extends StatelessWidget {
  const PoweredByNominatimNote({super.key, this.textStyle, this.linkStyle});

  final TextStyle? textStyle;
  final TextStyle? linkStyle;

  static final Uri _osmCopyrightUri = Uri.parse(
    'https://www.openstreetmap.org/copyright',
  );
  static final Uri _nominatimUri = Uri.parse('https://nominatim.org/');

  @override
  Widget build(BuildContext context) {
    final baseStyle = textStyle ?? Theme.of(context).textTheme.bodySmall;
    final effectiveLinkStyle =
        linkStyle ?? baseStyle?.copyWith(decoration: TextDecoration.underline);

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Powered by', style: baseStyle),
        _LinkText(
          label: 'Nominatim',
          uri: _nominatimUri,
          style: effectiveLinkStyle,
        ),
        Text('(© OpenStreetMap contributors, ODbL) –', style: baseStyle),
        _LinkText(
          label: 'OpenStreetMap copyright',
          uri: _osmCopyrightUri,
          style: effectiveLinkStyle,
        ),
      ],
    );
  }
}

class MapDataAttributionOverlay extends StatelessWidget {
  const MapDataAttributionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontSize: 11,
      height: 1.2,
    );
    final linkStyle = textStyle?.copyWith(decoration: TextDecoration.underline);

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: EsriAttributionService.copyrightText,
              builder: (context, snapshot) {
                final text =
                    snapshot.data ?? EsriAttributionService.fallbackAttribution;
                return Text(text, style: textStyle);
              },
            ),
            const SizedBox(height: 4),
            PoweredByNominatimNote(textStyle: textStyle, linkStyle: linkStyle),
          ],
        ),
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, required this.uri, this.style});

  final String label;
  final Uri uri;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchUri(context),
        child: Text(label, style: style),
      ),
    );
  }

  Future<void> _launchUri(BuildContext context) async {
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link konnte nicht geöffnet werden: ${uri.toString()}'),
        ),
      );
    }
  }
}
