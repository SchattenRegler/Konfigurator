import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/provider_attributions.dart';

class MapAttributionOverlay extends StatelessWidget {
  const MapAttributionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 11, color: Colors.white);
    return RichAttributionWidget(
      showFlutterMapAttribution: false,
      attributions: [
        WidgetSourceAttribution(
          widget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ProviderAttributions.esriImageryText,
                style: textStyle,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: -4,
                children: const [
                  _AttributionLink(
                    label: 'Esri Data Attribution Terms',
                    uri: ProviderAttributions.esriDataAttributionUri,
                  ),
                  _AttributionLink(
                    label: 'Esri Services Terms',
                    uri: ProviderAttributions.esriServicesUri,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ProviderAttributions.nominatimMapOverlayText,
                style: textStyle,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: -4,
                children: const [
                  _AttributionLink(
                    label: 'nominatim.org',
                    uri: ProviderAttributions.nominatimSiteUri,
                  ),
                  _AttributionLink(
                    label: 'OpenStreetMap Copyright & ODbL',
                    uri: ProviderAttributions.osmCopyrightUri,
                  ),
                  _AttributionLink(
                    label: 'Nominatim Terms of Use',
                    uri: ProviderAttributions.nominatimUsagePolicyUri,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PoweredByNominatimNotice extends StatelessWidget {
  const PoweredByNominatimNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          const Icon(Icons.info_outline, size: 14),
          Text(
            ProviderAttributions.nominatimNoticeText,
            style: textStyle,
          ),
          const _AttributionLink(
            label: 'nominatim.org',
            uri: ProviderAttributions.nominatimSiteUri,
          ),
          const _AttributionLink(
            label: 'OpenStreetMap Copyright',
            uri: ProviderAttributions.osmCopyrightUri,
          ),
        ],
      ),
    );
  }
}

class _AttributionLink extends StatelessWidget {
  const _AttributionLink({
    required this.label,
    required this.uri,
  });

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _launchUri(context, uri),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        textStyle: const TextStyle(fontSize: 11),
      ),
      child: Text(label),
    );
  }
}

Future<void> _launchUri(BuildContext context, Uri uri) async {
  final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!success) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text('Link konnte nicht geöffnet werden: ${uri.toString()}')),
    );
  }
}
