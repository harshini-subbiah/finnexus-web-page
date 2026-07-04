import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/loan_service.dart';
import '../../models/loan_model.dart';

class MyLoansScreen extends StatelessWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('My Loans',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.go('/loan-apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF82),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Apply', style: TextStyle(color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<List<LoanModel>>(
            stream: LoanService().streamUserLoans(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent)));
              }
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4CAF82)));
              }
              final loans = snapshot.data!;
              if (loans.isEmpty) {
                return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        const Text('No loans yet',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/loan-apply'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF82)),
                          child: const Text('Apply for a Loan',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ]),
                );
              }
              return ListView.separated(
                itemCount: loans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _LoanCard(loan: loans[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  const _LoanCard({required this.loan});

  Color get _statusColor {
    switch (loan.status) {
      case 'active': return Colors.greenAccent;
      case 'approved': return const Color(0xFF6C63FF);
      case 'closed': return Colors.white38;
      case 'rejected': return Colors.redAccent;
      default: return const Color(0xFFFFB347);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('₹${loan.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _statusColor.withOpacity(0.5)),
            ),
            child: Text(loan.status.toUpperCase(),
                style: TextStyle(color: _statusColor,
                    fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Lender: ${loan.lenderName}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text('Type: ${loan.loanType}',
            style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Text('Purpose: ${loan.purpose}',
            style: const TextStyle(color: Colors.white60)),
        Text('Tenure: ${loan.tenureMonths} months',
            style: const TextStyle(color: Colors.white60)),
        if (loan.interestRate != null)
          Text('Interest Rate: ${loan.interestRate}% p.a.',
              style: const TextStyle(color: Colors.white60)),
        if (loan.status == 'active')
          Text('EMIs paid: ${loan.emiHistory.length}',
              style: const TextStyle(
                  color: Colors.greenAccent, fontSize: 13)),
        if (loan.rejectionReason != null)
          Text('Reason: ${loan.rejectionReason}',
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 13)),
        Text('Applied: ${loan.createdAt.toLocal().toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}