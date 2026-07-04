import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/workflow_stepper.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState
    extends State<RoleSelectionScreen> {
  String? _selectedRole;

  final roles = [
    {
      'id': 'customer',
      'label': 'Customer',
      'desc': 'Buy products & services',
      'icon': '🛍️'
    },
    {
      'id': 'vendor',
      'label': 'Vendor',
      'desc': 'Sell products & manage supply',
      'icon': '🏭'
    },
    {
      'id': 'lender',
      'label': 'Lender',
      'desc': 'Provide loans & financing',
      'icon': '🏦'
    },
    {
      'id': 'insurer',
      'label': 'Insurer',
      'desc': 'Provide insurance policies',
      'icon': '🛡️'
    },
    {
      'id': 'advisor',
      'label': 'Advisor',
      'desc': 'Financial & business consulting',
      'icon': '💼'
    },
    {
      'id': 'logistics',
      'label': 'Logistics Partner',
      'desc': 'Handle deliveries & freight',
      'icon': '🚚'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 560,
            padding: const EdgeInsets.symmetric(
                horizontal: 40, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Workflow stepper — step 1
                const WorkflowStepper(
                  steps: Workflows.onboarding,
                  currentStep: 1,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 24),

                const Text('Select Your Role',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                const Text(
                    'This determines your dashboard and features',
                    style:
                        TextStyle(color: Colors.white54)),
                const SizedBox(height: 24),
                ...roles.map((r) => _RoleTile(
                      role: r,
                      selected:
                          _selectedRole == r['id'],
                      onTap: () => setState(
                          () => _selectedRole = r['id']),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedRole == null
                        ? null
                        : () => context.go('/business',
                            extra: _selectedRole),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6C63FF),
                      disabledBackgroundColor:
                          const Color(0xFF2D2D4E),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final Map<String, String> role;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile(
      {required this.role,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.15)
              : const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : const Color(0xFF2D2D4E),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(role['icon']!,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(role['label']!,
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              Text(role['desc']!,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12)),
            ],
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_circle,
                color: Color(0xFF6C63FF)),
        ]),
      ),
    );
  }
}