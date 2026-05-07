import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/handshake_service.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _manualSlug;
  bool _showManualEntry = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String? code) async {
    if (code == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final dio = ref.read(apiClientProvider);
      final handshakeService = HandshakeService(dio);
      final slug = handshakeService.extractSlugFromQRUrl(code);

      if (slug == null) {
        _showError('Invalid QR code format');
        setState(() => _isProcessing = false);
        return;
      }

      final authState = ref.read(authNotifierProvider);
      if (authState.firebaseUser == null) {
        _showError('Not authenticated');
        setState(() => _isProcessing = false);
        return;
      }

      final response = await handshakeService.performHandshake(
        slug: slug,
        firebaseUid: authState.firebaseUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.welcomeMessage ?? 'Handshake successful!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/home');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _performManualHandshake() async {
    if (_manualSlug == null || _manualSlug!.isEmpty) {
      _showError('Please enter a slug');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final dio = ref.read(apiClientProvider);
      final handshakeService = HandshakeService(dio);
      final authState = ref.read(authNotifierProvider);

      if (authState.firebaseUser == null) {
        _showError('Not authenticated');
        return;
      }

      final response = await handshakeService.performHandshake(
        slug: _manualSlug!,
        firebaseUid: authState.firebaseUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.welcomeMessage ?? 'Handshake successful!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/home');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
          ),
        ],
      ),
      body: _showManualEntry
          ? _buildManualEntry()
          : Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      _handleQRCode(barcode.rawValue);
                    }
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: Spacing.lg,
                  left: Spacing.lg,
                  right: Spacing.lg,
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Position QR code in frame',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Access Link Slug',
            style: AppTypography.h3,
          ),
          const SizedBox(height: Spacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: 'Slug',
              hintText: 'e.g., my-vault-link',
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (value) => _manualSlug = value,
            enabled: !_isProcessing,
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _performManualHandshake,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Connect'),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showManualEntry = false),
              child: const Text('Back to QR Scanner'),
            ),
          ),
        ],
      ),
    );
  }
}
