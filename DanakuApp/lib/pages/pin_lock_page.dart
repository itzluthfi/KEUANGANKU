import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class PinLockPage extends StatefulWidget {
  final bool isConfirming; 
  final String? setupPin; 
  
  const PinLockPage({super.key, this.isConfirming = false, this.setupPin});

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  String _enteredCode = "";
  String? _savedPin;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadSavedPin();
  }

  Future<void> _loadSavedPin() async {
    final pin = await DatabaseHelper.instance.getSetting('secure_pin');
    setState(() {
      _savedPin = pin;
    });
  }

  void _onKeyPress(String value) {
    if (_enteredCode.length < 4) {
      setState(() {
        _enteredCode += value;
        _errorMessage = "";
      });
    }

    if (_enteredCode.length == 4) {
      // Small delay to let user see last filled dot
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _verifyCode();
      });
    }
  }

  void _onDelete() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
        _errorMessage = "";
      });
    }
  }

  void _verifyCode() async {
    // Mode Set Up PIN Baru (Konfirmasi)
    if (widget.isConfirming) {
      if (_enteredCode == widget.setupPin) {
        await DatabaseHelper.instance.saveSetting('secure_pin', _enteredCode);
        await DatabaseHelper.instance.saveSetting('pin_enabled', 'true');
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _enteredCode = "";
          _errorMessage = "PIN Konfirmasi tidak cocok. Coba lagi.";
        });
      }
      return;
    }

    // Mode Pembukaan Kunci / Set Up awal
    if (_savedPin != null) {
      if (_enteredCode == _savedPin) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _enteredCode = "";
          _errorMessage = "PIN salah. Coba lagi.";
        });
      }
    } else {
      // Jika belum ada PIN sama sekali, arahkan ke layar konfirmasi
      final confirm = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinLockPage(isConfirming: true, setupPin: _enteredCode),
        ),
      );
      if (confirm == true) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _enteredCode = "";
        });
      }
    }
  }

  Widget _buildDot(int index) {
    bool isFilled = index < _enteredCode.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isFilled ? Colors.white : Colors.white24,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // Logo/Icon
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                widget.isConfirming 
                    ? "Konfirmasi PIN Baru Anda" 
                    : (_savedPin == null ? "Buat PIN Baru Anda" : "Masukkan PIN Keamanan"),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildDot(index)),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              // Keypad Grid
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKeypadButton("1"),
                        _buildKeypadButton("2"),
                        _buildKeypadButton("3"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKeypadButton("4"),
                        _buildKeypadButton("5"),
                        _buildKeypadButton("6"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildKeypadButton("7"),
                        _buildKeypadButton("8"),
                        _buildKeypadButton("9"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Clear button or empty placeholder
                        const SizedBox(width: 70, height: 70),
                        _buildKeypadButton("0"),
                        InkWell(
                          onTap: _onDelete,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
