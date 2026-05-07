import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/api_client_provider.dart';

class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _routingNumberController;
  bool _showFullNumber = false;
  bool _isSaving = false;

  String? _maskedAccountNumber;
  String? _bankName;

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController();
    _bankNameController = TextEditingController();
    _routingNumberController = TextEditingController();
    _loadBankAccount();
  }

  Future<void> _loadBankAccount() async {
    try {
      // TODO: Load from API or local state
      // final vault = await apiService.getVault();
      // _maskedAccountNumber = vault.maskedAccountNumber;
      // _bankName = vault.bankAccountData?['bank_name'];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bank account: $e')),
      );
    }
  }

  Future<void> _saveBankAccount() async {
    if (_accountNumberController.text.isEmpty ||
        _bankNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch(
        '/my/vault',
        data: {
          'vault': {
            'bank_account_info': {
              'account_number': _accountNumberController.text,
              'bank_name': _bankNameController.text,
              'routing_number': _routingNumberController.text,
            }
          }
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account saved securely')),
        );
        final vaultData = response.data['vault'];
        setState(() {
          _maskedAccountNumber = vaultData['masked_account_number'];
          _bankName = vaultData['bank_account_info']?['bank_name'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _routingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display section (only show if data exists)
            if (_maskedAccountNumber != null) ...[
              Text(
                'Current Account',
                style: AppTypography.h3,
              ),
              const SizedBox(height: Spacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Number',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: Spacing.sm),
                                Text(
                                  _showFullNumber
                                      ? _accountNumberController.text
                                      : _maskedAccountNumber!,
                                  style: AppTypography.h3,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showFullNumber
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showFullNumber = !_showFullNumber,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.content_copy),
                                onPressed: () => _copyToClipboard(
                                  _accountNumberController.text,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bank Name',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: Spacing.sm),
                                Text(_bankName ?? '', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Update Account',
                style: AppTypography.h3,
              ),
            ] else
              Text(
                'Add Bank Account',
                style: AppTypography.h2,
              ),
            const SizedBox(height: Spacing.md),
            // Edit form
            TextField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Account Number',
                prefixIcon: const Icon(Icons.account_balance),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'Bank Name',
                prefixIcon: const Icon(Icons.business),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _routingNumberController,
              decoration: InputDecoration(
                labelText: 'Routing Number (Optional)',
                prefixIcon: const Icon(Icons.route),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: Spacing.lg),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange[700]),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      'Bank account information is encrypted and stored securely.',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBankAccount,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save Bank Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
