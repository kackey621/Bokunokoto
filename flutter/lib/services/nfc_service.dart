import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  static Future<bool> isSupported() async {
    return await NfcManager.instance.isAvailable();
  }

  static Future<String?> scanNFC() async {
    if (!await isSupported()) return null;

    String? data;
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NdefMessage message) async {
          for (NdefRecord record in message.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellKnown &&
                record.type.codeUnits == 'U'.codeUnits) {
              final uri = record.payloadAsString;
              data = uri;
              break;
            }
          }
        },
      );
    } catch (e) {
      data = null;
    } finally {
      await NfcManager.instance.stopSession();
    }
    return data;
  }

  static Future<void> writeAccessLinkToTag(String slug) async {
    if (!await isSupported()) throw Exception('NFC not supported');

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NdefMessage message) async {
          final ndefRecord = NdefRecord.createUri(
            Uri.parse('https://bk.app/p/$slug'),
          );

          await NfcManager.instance.completionStream();
        },
      );
    } catch (e) {
      throw Exception('Failed to write NFC tag: $e');
    }
  }
}
