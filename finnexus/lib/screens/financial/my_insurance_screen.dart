import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/insurance_service.dart';
import '../../models/insurance_model.dart';

class MyInsuranceScreen extends StatelessWidget {
  const MyInsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(children: [
            const Text('My Insurance Policies',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => context.go('/insurance-apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B39),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label:
                  const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<InsuranceModel>>(
            stream: InsuranceService().streamUserPolicies(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 12),
                      Text('${snapshot.error}',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE07B39)));
              }
              final policies = snapshot.data!;
              if (policies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      const Text('No insurance policies yet',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/insurance-apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE07B39),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Apply for Insurance',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: policies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _PolicyCard(policy: policies[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final InsuranceModel policy;
  const _PolicyCard({required this.policy});

  Color get _color {
    switch (policy.status) {
      case 'active':
        return Colors.greenAccent;
      case 'settled':
        return const Color(0xFF6C63FF);
      case 'claim_filed':
        return const Color(0xFFFFB347);
      case 'closed':
        return Colors.white38;
      default:
        return const Color(0xFFFFB347);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(policy.type == 'trade_credit' ? '🤝' : '🚚',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  policy.type == 'trade_credit'
                      ? 'Trade Credit Insurance'
                      : 'Goods in Transit Insurance',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _color.withOpacity(0.5)),
                ),
                child: Text(
                    policy.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                        color: _color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),
            if (policy.insurerName.isNotEmpty)
              Text('Insurer: ${policy.insurerName}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            Text(
                'Coverage: ₹${policy.coverageAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white60)),
            if (policy.buyerCustomerId != null)
              Text('Buyer ID: ${policy.buyerCustomerId}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
            if (policy.shipmentOrigin != null)
              Text(
                  'Route: ${policy.shipmentOrigin} → ${policy.shipmentDestination}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
            if (policy.claimReason != null)
              Text('Claim: ${policy.claimReason}',
                  style: const TextStyle(
                      color: Color(0xFFFFB347), fontSize: 12)),
            Text(
                'Applied: ${policy.createdAt.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
          ]),
    );
  }
}