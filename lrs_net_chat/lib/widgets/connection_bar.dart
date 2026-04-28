import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lrs_provider.dart';
import '../theme/app_theme.dart';

class ConnectionBar extends StatelessWidget {
  const ConnectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final connected = context.watch<LrsProvider>().isConnected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: connected
              ? [AppTheme.success.withValues(alpha: 0.15), AppTheme.surface]
              : [AppTheme.danger.withValues(alpha: 0.15), AppTheme.surface],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingDot(color: connected ? AppTheme.success : AppTheme.danger),
          const SizedBox(width: 10),
          Text(
            connected ? 'Connected' : 'No signal',
            style: TextStyle(
              color: connected ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Container(
        width: 10 * _scale.value,
        height: 10 * _scale.value,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 8 * _scale.value,
            ),
          ],
        ),
      ),
    );
  }
}
