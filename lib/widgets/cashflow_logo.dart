// lib/widgets/cashflow_logo.dart

import 'package:flutter/material.dart';

class CashFlowLogo extends StatelessWidget {
  final double size;
  final double iconSize;

  const CashFlowLogo({
    super.key,
    this.size = 64.0,
    this.iconSize = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF10B981).withValues(alpha: 0.2),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0F3D35),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: const Color(0xFF34D399),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
