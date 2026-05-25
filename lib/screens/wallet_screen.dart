import 'dart:async';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  
  // Tab control: 0 = Deposit, 1 = Withdraw
  int _activeTab = 0;

  // Deposit Form State
  final _depositFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  // Withdraw Form State
  final _withdrawFormKey = GlobalKey<FormState>();
  final _withdrawBankController = TextEditingController();
  final _withdrawAccController = TextEditingController();
  final _withdrawIfscController = TextEditingController();
  final _withdrawAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_updateState);
  }

  @override
  void dispose() {
    _walletService.removeListener(_updateState);
    _amountController.dispose();
    _withdrawBankController.dispose();
    _withdrawAccController.dispose();
    _withdrawIfscController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  void _quickSelectAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  // Open the simulated bank deposit dialog
  void _openDepositGateway() {
    if (!_depositFormKey.currentState!.validate()) return;
    
    final double depositAmount = double.parse(_amountController.text.trim());
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SimulatedBankGatewayDialog(
          amount: depositAmount,
          onSuccess: (amount) {
            _walletService.addFunds(amount);
            _amountController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Successfully added ₹${amount.toStringAsFixed(2)} to eWallet!"),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
        );
      },
    );
  }

  // Handle Bank Withdrawal
  void _processWithdrawal() async {
    if (!_withdrawFormKey.currentState!.validate()) return;

    final bankName = _withdrawBankController.text.trim();
    final accountNo = _withdrawAccController.text.trim();
    final ifsc = _withdrawIfscController.text.trim().toUpperCase();
    final double amount = double.parse(_withdrawAmountController.text.trim());

    FocusScope.of(context).unfocus();

    if (amount > _walletService.balance) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardNavy,
          title: const Text("Insufficient Balance", style: TextStyle(color: AppTheme.errorRed)),
          content: const Text(
            "Your eWallet balance is lower than the withdrawal amount requested. Please check and try again.",
            style: TextStyle(color: AppTheme.textWhite),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: AppTheme.goldAccent)),
            ),
          ],
        ),
      );
      return;
    }

    final bankDetails = "$bankName A/C ...${accountNo.substring(accountNo.length > 4 ? accountNo.length - 4 : 0)} (IFSC: $ifsc)";
    final success = await _walletService.withdrawFunds(amount, bankDetails);

    if (success) {
      _withdrawBankController.clear();
      _withdrawAccController.clear();
      _withdrawIfscController.clear();
      _withdrawAmountController.clear();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.successGreen),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppTheme.successGreen),
              SizedBox(width: 8),
              Text("Withdrawal Requested", style: TextStyle(color: AppTheme.textWhite, fontSize: 16)),
            ],
          ),
          content: Text(
            "An amount of ₹${amount.toStringAsFixed(2)} has been successfully debited and transferred to your bank account.\n\nBank: $bankName\nAccount: $accountNo",
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _walletService.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text("IRCTC eWALLET")),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Digital Wallet Card
              _buildDigitalWalletCard(),
              const SizedBox(height: 20),

              // Segmented Tab Selector
              _buildSegmentedTabSelector(),
              const SizedBox(height: 20),

              // Active Tab Form Container
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _activeTab == 0 ? _buildDepositForm() : _buildWithdrawForm(),
              ),
              const SizedBox(height: 24),

              // Ledger Transactions List
              const Text(
                "TRANSACTION LEDGER",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.goldAccent),
              ),
              const SizedBox(height: 12),

              if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text("No transactions recorded yet.", style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    final isCredit = txn.type == WalletTransactionType.credit;

                    return Card(
                      color: AppTheme.cardNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.primaryLightNavy.withOpacity(0.6)),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCredit ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          txn.description,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13),
                        ),
                        subtitle: Text(
                          "ID: ${txn.id} | ${txn.formattedDate}",
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          "${isCredit ? '+' : '-'} ${txn.formattedAmount}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isCredit ? AppTheme.successGreen : AppTheme.errorRed,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalWalletCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, AppTheme.goldDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "IRCTC eWallet",
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0),
                  ),
                  Text(
                    "Active Member Account",
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.train_rounded, color: AppTheme.goldAccent, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TOTAL BALANCE",
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
              ),
              const SizedBox(height: 2),
              Text(
                "₹${_walletService.balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? AppTheme.goldAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "DEPOSIT FUNDS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _activeTab == 0 ? AppTheme.primaryNavy : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? AppTheme.goldAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "WITHDRAW TO BANK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _activeTab == 1 ? AppTheme.primaryNavy : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. DEPOSIT FORM
  Widget _buildDepositForm() {
    return Container(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Form(
        key: _depositFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "ADD FUNDS TO WALLET",
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            
            // Amount Input
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: AppTheme.textWhite),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (₹)",
                hintText: "Enter amount to add",
                prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.goldAccent),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty || double.tryParse(value.trim()) == null) {
                  return "Enter a valid amount";
                }
                if (double.parse(value.trim()) <= 0) {
                  return "Must be greater than 0";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Quick Selection Tags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAmountTag(500),
                _buildQuickAmountTag(1000),
                _buildQuickAmountTag(2000),
                _buildQuickAmountTag(5000),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _openDepositGateway,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_card_rounded, size: 18),
                  SizedBox(width: 8),
                  Text("ADD MONEY"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountTag(double amount) {
    return InkWell(
      onTap: () => _quickSelectAmount(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLightNavy.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryLightNavy),
        ),
        child: Text(
          "+₹${amount.toInt()}",
          style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  // 2. WITHDRAW FORM
  Widget _buildWithdrawForm() {
    return Container(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Form(
        key: _withdrawFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "WITHDRAW WALLET BALANCE TO BANK",
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            
            // Bank Name Input
            TextFormField(
              controller: _withdrawBankController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: const InputDecoration(
                labelText: "Bank Name",
                hintText: "e.g. State Bank of India",
                prefixIcon: Icon(Icons.account_balance_rounded, color: AppTheme.goldAccent),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Enter Bank Name";
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Account Number Input
            TextFormField(
              controller: _withdrawAccController,
              style: const TextStyle(color: AppTheme.textWhite),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Account Number",
                hintText: "Enter full account number",
                prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.goldAccent),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Enter Account Number";
                if (value.trim().length < 8) return "Must be at least 8 digits";
                return null;
              },
            ),
            const SizedBox(height: 12),

            // IFSC Code Input
            TextFormField(
              controller: _withdrawIfscController,
              style: const TextStyle(color: AppTheme.textWhite),
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "IFSC Code",
                hintText: "e.g. SBIN0000123",
                prefixIcon: Icon(Icons.qr_code_rounded, color: AppTheme.goldAccent),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return "Enter IFSC Code";
                if (value.trim().length != 11) return "IFSC must be exactly 11 characters";
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Withdrawal Amount
            TextFormField(
              controller: _withdrawAmountController,
              style: const TextStyle(color: AppTheme.textWhite),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Withdrawal Amount (₹)",
                hintText: "Enter amount to withdraw",
                prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.goldAccent),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty || double.tryParse(value.trim()) == null) {
                  return "Enter a valid amount";
                }
                if (double.parse(value.trim()) <= 0) {
                  return "Must be greater than 0";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _processWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: AppTheme.textWhite,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.output_rounded, size: 18),
                  SizedBox(width: 8),
                  Text("WITHDRAW FUNDS"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SIMULATED BANK GATEWAY DIALOG (Interactive Stateful Widget inside dialog)
class _SimulatedBankGatewayDialog extends StatefulWidget {
  final double amount;
  final Function(double) onSuccess;

  const _SimulatedBankGatewayDialog({
    required this.amount,
    required this.onSuccess,
  });

  @override
  State<_SimulatedBankGatewayDialog> createState() => _SimulatedBankGatewayDialogState();
}

class _SimulatedBankGatewayDialogState extends State<_SimulatedBankGatewayDialog> {
  // Steps: 0 = Bank & Mode selection, 1 = Credentials, 2 = Loading spinner, 3 = OTP screen, 4 = Success
  int _step = 0;

  String _selectedBank = "SBI";
  String _paymentMode = "UPI"; // UPI, NetBanking, Card

  // Mode inputs
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  final _cardNoCtrl = TextEditingController();
  final _cardExpCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  // OTP controller
  final _otpCtrl = TextEditingController();
  String? _otpError;

  final _formKeyMode = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();

  final List<Map<String, String>> _banks = [
    {"code": "SBI", "name": "State Bank of India"},
    {"code": "HDFC", "name": "HDFC Bank"},
    {"code": "ICICI", "name": "ICICI Bank"},
    {"code": "PNB", "name": "Punjab National Bank"},
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _upiIdCtrl.dispose();
    _cardNoCtrl.dispose();
    _cardExpCtrl.dispose();
    _cardCvvCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _goToCredentials() {
    setState(() {
      _step = 1;
    });
  }

  void _startSecureAuthorization() {
    if (!_formKeyMode.currentState!.validate()) return;

    setState(() {
      _step = 2; // spinner
    });

    // Simulate gateway delay
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _step = 3; // OTP
        });
      }
    });
  }

  void _verifyOtp() {
    if (!_formKeyOtp.currentState!.validate()) return;
    
    final code = _otpCtrl.text.trim();
    if (code == "123456") {
      setState(() {
        _otpError = null;
        _step = 4; // Success
      });
    } else {
      setState(() {
        _otpError = "Invalid OTP. Use demo OTP 123456";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 400,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gateway Header
              _buildGatewayHeader(),
              
              // Gateway Body depending on Step
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildBodyForStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: const Color(0xFF1A365D), // Dark premium bank-themed blue
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.security_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "SECURE BANK GATEWAY",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "₹${widget.amount.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBodyForStep() {
    switch (_step) {
      case 0:
        return _buildStep0BankSelector();
      case 1:
        return _buildStep1CredentialsInput();
      case 2:
        return _buildStep2LoadingSpinner();
      case 3:
        return _buildStep3OtpVerification();
      case 4:
        return _buildStep4Success();
      default:
        return Container();
    }
  }

  // STEP 0: BANK AND MODE SELECTOR
  Widget _buildStep0BankSelector() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Select Your Banking Partner:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: _banks.length,
          itemBuilder: (context, index) {
            final b = _banks[index];
            final isSelected = _selectedBank == b["code"];
            return InkWell(
              onTap: () => setState(() => _selectedBank = b["code"]!),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEBF8FF) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3182CE) : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    b["name"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF2B6CB0) : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          "Choose Payment Method:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildModeRadio("UPI ID", "UPI"),
            _buildModeRadio("NetBanking", "NetBanking"),
            _buildModeRadio("Debit Card", "Card"),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _goToCredentials,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3182CE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text("PROCEED TO SECURE BANK", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel Deposit", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildModeRadio(String label, String value) {
    final isSelected = _paymentMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentMode = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDF2F7) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isSelected ? const Color(0xFF4A5568) : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2D3748) : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // STEP 1: CREDENTIALS INPUT
  Widget _buildStep1CredentialsInput() {
    return Form(
      key: _formKeyMode,
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Authorized Portal: $_selectedBank",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 14),
          
          if (_paymentMode == "UPI") ...[
            TextFormField(
              controller: _upiIdCtrl,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "Enter UPI ID",
                hintText: "username@bank",
                labelStyle: TextStyle(color: Colors.black54),
                hintStyle: TextStyle(color: Colors.black38),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty || !v.contains("@")) return "Enter valid UPI ID";
                return null;
              },
            ),
          ] else if (_paymentMode == "NetBanking") ...[
            TextFormField(
              controller: _usernameCtrl,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "NetBanking Username",
                labelStyle: TextStyle(color: Colors.black54),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Enter Username";
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.black54),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return "Enter Password";
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _cardNoCtrl,
              style: const TextStyle(color: Colors.black87),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Debit Card Number",
                hintText: "1234 5678 9012 3456",
                labelStyle: TextStyle(color: Colors.black54),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty || v.trim().length < 12) return "Enter valid card number";
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardExpCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: "Expiry",
                      hintText: "MM/YY",
                      labelStyle: TextStyle(color: Colors.black54),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    validator: (v) => v == null || !v.contains("/") ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _cardCvvCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black87),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      labelStyle: TextStyle(color: Colors.black54),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    validator: (v) => v == null || v.length < 3 ? "Required" : null,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startSecureAuthorization,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182CE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("AUTHORIZE SECURE TRANSACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _step = 0;
              });
            },
            child: const Text("Back", style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  // STEP 2: SPINNER LOADING GATEWAY
  Widget _buildStep2LoadingSpinner() {
    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          color: Color(0xFF3182CE),
        ),
        const SizedBox(height: 20),
        Text(
          "Connecting to $_selectedBank secure host...",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 12),
        ),
        const SizedBox(height: 10),
        const Text(
          "Please do not reload, go back, or close this window.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // STEP 3: OTP VERIFICATION
  Widget _buildStep3OtpVerification() {
    return Form(
      key: _formKeyOtp,
      child: Column(
        key: const ValueKey(3),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.sms_rounded, color: Color(0xFF3182CE), size: 36),
          const SizedBox(height: 10),
          const Text(
            "Enter OTP Verification Code",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            "A simulated One-Time Password (OTP) has been generated for your transaction. Enter the demo code below.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpCtrl,
            style: const TextStyle(color: Colors.black87, fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: "Demo OTP (Use: 123456)",
              labelStyle: const TextStyle(color: Colors.black54, letterSpacing: 0, fontSize: 12),
              errorText: _otpError,
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3182CE))),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Enter OTP";
              if (v.trim().length != 6) return "Must be 6 digits";
              return null;
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182CE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("VERIFY & CONFIRM PAY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel Payment", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // STEP 4: SUCCESS CONFIRMATION
  Widget _buildStep4Success() {
    return Column(
      key: const ValueKey(4),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
        const SizedBox(height: 16),
        const Text(
          "Payment Authorized!",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          "Successfully fetched ₹${widget.amount.toStringAsFixed(2)} from $_selectedBank.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          "Your eWallet has been credited successfully.",
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onSuccess(widget.amount); // trigger state update & Snackbar
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("CLOSE GATEWAY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
