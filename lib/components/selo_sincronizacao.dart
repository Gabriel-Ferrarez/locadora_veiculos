import 'package:flutter/material.dart';

/// Selo que mostra se a locação já está na API ou se está pendente.
class SeloSincronizacao extends StatelessWidget {
  final bool sincronizado;

  const SeloSincronizacao({super.key, required this.sincronizado});

  static const Color corSincronizado = Color(0xFF2E7D32);
  static const Color corPendente = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    final Color cor = sincronizado ? corSincronizado : corPendente;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sincronizado ? Icons.cloud_done : Icons.cloud_off,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: 4),
          Text(
            sincronizado ? 'Sincronizada' : 'Pendente',
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
