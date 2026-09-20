import 'package:flutter/material.dart';

/// 4x4 Custom Numeric Keypad for cost entry.
class CostKeypad extends StatelessWidget {
  const CostKeypad({
    super.key,
    required this.onKeyPress,
    required this.onPickDate,
    required this.dateLabel,
    required this.onSubmit,
    required this.isSubmitting,
    required this.primaryColor,
  });

  final void Function(String key) onKeyPress;
  final VoidCallback onPickDate;
  final String dateLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final Color primaryColor;

  Widget _key(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onKeyPress(label),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateKey(String label) {
    return Material(
      color: const Color(0xFFEFECE6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPickDate,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF1B1D1F),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1D1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return Material(
      color: const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onKeyPress('⌫'),
        borderRadius: BorderRadius.circular(16),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 18,
            color: Color(0xFF1B1D1F),
          ),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: isSubmitting ? null : onSubmit,
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 32, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First 3 columns (Grid: 3 cols x 4 rows)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _key('7'),
                      _key('8'),
                      _key('9'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _key('4'),
                      _key('5'),
                      _key('6'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _key('1'),
                      _key('2'),
                      _key('3'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _key('.'),
                      _key('0'),
                      _key('00'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 4th column (Date, Backspace, Big Submit Button)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _dateKey(dateLabel)),
                const SizedBox(height: 8),
                Expanded(child: _backspaceKey()),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: _submitButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
