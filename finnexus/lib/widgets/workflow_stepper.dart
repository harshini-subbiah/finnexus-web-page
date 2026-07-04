import 'package:flutter/material.dart';

class WorkflowStep {
  final String label;
  final String description;
  final IconData icon;

  const WorkflowStep({
    required this.label,
    required this.description,
    required this.icon,
  });
}

class WorkflowStepper extends StatelessWidget {
  final List<WorkflowStep> steps;
  final int currentStep;
  final Color color;

  const WorkflowStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.color = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(Icons.account_tree_outlined,
                color: color, size: 14),
            const SizedBox(width: 6),
            Text('Process Overview',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
                'Step ${currentStep + 1} of ${steps.length}',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11)),
          ]),
          const SizedBox(height: 14),

          // Horizontal timeline
          SizedBox(
            height: 64,
            child: Row(
              children:
                  List.generate(steps.length, (i) {
                final isDone = i < currentStep;
                final isCurrent = i == currentStep;
                final isLast = i == steps.length - 1;

                Color dotColor;
                if (isDone) {
                  dotColor = Colors.greenAccent;
                } else if (isCurrent) {
                  dotColor = color;
                } else {
                  dotColor = const Color(0xFF2D2D4E);
                }

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox()
                              : Container(
                                  height: 2,
                                  color: i <= currentStep
                                      ? Colors.greenAccent
                                          .withOpacity(0.5)
                                      : const Color(
                                          0xFF2D2D4E),
                                ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: dotColor
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: dotColor,
                                width:
                                    isCurrent ? 2 : 1.5),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check,
                                    color:
                                        Colors.greenAccent,
                                    size: 14)
                                : Icon(steps[i].icon,
                                    color: isCurrent
                                        ? color
                                        : Colors.white24,
                                    size: 13),
                          ),
                        ),
                        Expanded(
                          child: isLast
                              ? const SizedBox()
                              : Container(
                                  height: 2,
                                  color: i < currentStep
                                      ? Colors.greenAccent
                                          .withOpacity(0.5)
                                      : const Color(
                                          0xFF2D2D4E),
                                ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDone
                              ? Colors.greenAccent
                              : isCurrent
                                  ? Colors.white
                                  : Colors.white24,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Current step description
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Icon(steps[currentStep].icon,
                  color: color, size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  steps[currentStep].description,
                  style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: 11),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Predefined workflows ──────────────────────────
class Workflows {
  static const List<WorkflowStep> onboarding = [
    WorkflowStep(
      label: 'Register',
      description:
          'Create your account with email and password',
      icon: Icons.person_add_outlined,
    ),
    WorkflowStep(
      label: 'Select Role',
      description:
          'Choose your business role on the platform',
      icon: Icons.badge_outlined,
    ),
    WorkflowStep(
      label: 'Business Details',
      description:
          'Enter GSTIN, PAN, bank account and address',
      icon: Icons.business_outlined,
    ),
    WorkflowStep(
      label: 'Upload KYC',
      description:
          'Upload GST certificate, PAN, Aadhaar, bank statement',
      icon: Icons.upload_file_outlined,
    ),
    WorkflowStep(
      label: 'Admin Review',
      description:
          'Our team verifies your documents (1–2 business days)',
      icon: Icons.hourglass_top_rounded,
    ),
    WorkflowStep(
      label: 'Approved',
      description:
          'Access your dashboard and all platform features',
      icon: Icons.check_circle_outline,
    ),
  ];

  static const List<WorkflowStep> loanApplication = [
    WorkflowStep(
      label: 'Choose Lender',
      description:
          'Browse approved lenders and select one',
      icon: Icons.account_balance_outlined,
    ),
    WorkflowStep(
      label: 'Fill Application',
      description:
          'Enter loan amount, type, income and collateral',
      icon: Icons.edit_note_outlined,
    ),
    WorkflowStep(
      label: 'Upload Docs',
      description:
          'Attach supporting financial documents',
      icon: Icons.attach_file,
    ),
    WorkflowStep(
      label: 'Lender Review',
      description: 'Lender reviews and sets interest rate',
      icon: Icons.manage_search_outlined,
    ),
    WorkflowStep(
      label: 'Disbursement',
      description: 'Loan approved and amount disbursed',
      icon: Icons.payments_outlined,
    ),
    WorkflowStep(
      label: 'Repayment',
      description:
          'Repay within tenure. CRR score updated on closure',
      icon: Icons.currency_rupee,
    ),
  ];

  static const List<WorkflowStep> insuranceApplication =
      [
    WorkflowStep(
      label: 'Choose Insurer',
      description:
          'Browse approved insurers on the platform',
      icon: Icons.business_outlined,
    ),
    WorkflowStep(
      label: 'Select Type',
      description:
          'Choose Trade Credit or Goods in Transit',
      icon: Icons.shield_outlined,
    ),
    WorkflowStep(
      label: 'Fill Details',
      description:
          'Enter coverage amount and business details',
      icon: Icons.edit_note_outlined,
    ),
    WorkflowStep(
      label: 'Insurer Review',
      description:
          'Insurer reviews and approves your application',
      icon: Icons.manage_search_outlined,
    ),
    WorkflowStep(
      label: 'Policy Active',
      description:
          'Policy is active — file claims through platform',
      icon: Icons.verified_outlined,
    ),
  ];

  static const List<WorkflowStep> orderPlacement = [
    WorkflowStep(
      label: 'Browse',
      description:
          'Search catalogue, filter by category or vendor',
      icon: Icons.storefront_outlined,
    ),
    WorkflowStep(
      label: 'Negotiate',
      description:
          'Chat with vendor to negotiate price before buying',
      icon: Icons.chat_bubble_outline,
    ),
    WorkflowStep(
      label: 'Add to Cart',
      description:
          'Select quantity and add items to your cart',
      icon: Icons.add_shopping_cart_outlined,
    ),
    WorkflowStep(
      label: 'Payment',
      description:
          'Pay now or use 30/60 day credit terms',
      icon: Icons.payment_outlined,
    ),
    WorkflowStep(
      label: 'Track',
      description:
          'Track shipment and confirm delivery with OTP',
      icon: Icons.local_shipping_outlined,
    ),
  ];
}