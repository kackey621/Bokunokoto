import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/theme.dart';

/// Renders a QR code that encodes an AccessLink in URL form. The viewer
/// app's scanner (see `services/handshake_service.dart#extractSlugFromQRUrl`)
/// reads the slug from the last path segment, so any URL whose last segment
/// is the slug — e.g. `https://bokunokoto.app/p/<slug>` — is valid.
class QrGeneratorScreen extends StatelessWidget {
  final String slug;
  final String? presetContext;
  final String? welcomeMessage;
  final String? bindHost;

  const QrGeneratorScreen({
    Key? key,
    required this.slug,
    this.presetContext,
    this.welcomeMessage,
    this.bindHost,
  }) : super(key: key);

  String get qrPayload => "${bindHost ?? 'https://bokunokoto.app'}/p/$slug";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share Access Link')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (presetContext != null && presetContext!.isNotEmpty) ...[
              Text(
                presetContext!,
                style: AppTypography.h3,
                textAlign: TextAlign.center,
                semanticsLabel: 'Context: $presetContext',
              ),
              const SizedBox(height: Spacing.sm),
            ],
            Text(
              welcomeMessage ?? 'Have the recipient scan this code to connect.',
              style: AppTypography.bodyMedium.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Semantics(
                  label: 'Access link QR code for slug $slug',
                  image: true,
                  child: QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SelectableText(
              qrPayload,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.md,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copy(context, qrPayload),
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Link'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copy(context, slug),
                  icon: const Icon(Icons.tag),
                  label: const Text('Copy Slug'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
