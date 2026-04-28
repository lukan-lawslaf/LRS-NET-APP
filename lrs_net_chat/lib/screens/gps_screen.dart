import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/lrs_provider.dart';
import '../theme/app_theme.dart';

class GpsScreen extends StatelessWidget {
  const GpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gps = context.watch<LrsProvider>().gpsData;

    if (gps == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.satellite_alt,
                size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'Waiting for GPS data…',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Data will appear when the hiker node transmits',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Fix status badge ────────────────────────────────
          _FixBadge(fix: gps.fix, label: gps.fixLabel),
          const SizedBox(height: 16),

          // ── Main GPS card ──────────────────────────────────
          _GlassCard(
            child: Column(
              children: [
                _DataRow(icon: Icons.my_location, label: 'Latitude', value: '${gps.lat}°'),
                const _Divider(),
                _DataRow(icon: Icons.my_location, label: 'Longitude', value: '${gps.lon}°'),
                const _Divider(),
                _DataRow(icon: Icons.terrain, label: 'Altitude', value: '${gps.alt} m'),
                const _Divider(),
                _DataRow(icon: Icons.explore, label: 'Course', value: '${gps.course}°'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Date / Time card ───────────────────────────────
          _GlassCard(
            child: Column(
              children: [
                _DataRow(icon: Icons.calendar_today, label: 'Date', value: gps.date),
                const _Divider(),
                _DataRow(icon: Icons.access_time, label: 'Time (UTC)', value: gps.time),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Signal card ────────────────────────────────────
          _GlassCard(
            child: Column(
              children: [
                _DataRow(
                  icon: Icons.signal_cellular_alt,
                  label: 'RSSI',
                  value: '${gps.rssi} dBm',
                  valueColor: _rssiColor(gps.rssi),
                ),
                const _Divider(),
                _DataRow(
                  icon: Icons.graphic_eq,
                  label: 'SNR',
                  value: '${gps.snr} dB',
                  valueColor: _snrColor(gps.snr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Open in Maps button ────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _openMaps(gps.mapsUrl),
              icon: const Icon(Icons.map_rounded, size: 22),
              label: const Text(
                'Open in Maps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppTheme.accent.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Last update ────────────────────────────────────
          Text(
            'Last update: ${gps.receivedAt.hour.toString().padLeft(2, '0')}:'
            '${gps.receivedAt.minute.toString().padLeft(2, '0')}:'
            '${gps.receivedAt.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _rssiColor(String rssi) {
    final val = int.tryParse(rssi) ?? -999;
    if (val > -80) return AppTheme.success;
    if (val > -110) return Colors.orange;
    return AppTheme.danger;
  }

  Color _snrColor(String snr) {
    final val = double.tryParse(snr) ?? -99;
    if (val > 5) return AppTheme.success;
    if (val > 0) return Colors.orange;
    return AppTheme.danger;
  }
}

// ── Fix badge ────────────────────────────────────────────────────
class _FixBadge extends StatelessWidget {
  final String fix;
  final String label;
  const _FixBadge({required this.fix, required this.label});

  @override
  Widget build(BuildContext context) {
    final hasFix = fix == '3' || fix == '2';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: (hasFix ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (hasFix ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFix ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: hasFix ? AppTheme.success : AppTheme.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: hasFix ? AppTheme.success : AppTheme.danger,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glassmorphism card ───────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Data row ─────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider ──────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppTheme.cardBorder.withValues(alpha: 0.4),
      height: 1,
      thickness: 0.5,
    );
  }
}
