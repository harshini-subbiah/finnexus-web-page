import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../business/business_profile_screen.dart';
import '../business/incoming_requests_screen.dart';
import '../financial/my_loans_screen.dart';
import '../financial/my_insurance_screen.dart';
import '../ecommerce/my_orders_screen.dart';
import '../ecommerce/vendor_products_screen.dart';
import '../ecommerce/buyer_chats_screen.dart';
import '../ecommerce/vendor_chats_screen.dart';
import '../advisory/advisor_sessions_screen.dart';
import '../advisory/my_advisory_screen.dart';
import '../logistics/logistics_screen.dart';
import '../profile/my_profile_screen.dart';

class UnifiedDashboardScreen extends StatefulWidget {
  const UnifiedDashboardScreen({super.key});
  @override
  State<UnifiedDashboardScreen> createState() =>
      _UnifiedDashboardScreenState();
}

class _UnifiedDashboardScreenState
    extends State<UnifiedDashboardScreen> {
  UserModel? _user;
  int _tab = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirestoreService().getUser(uid);
    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'lender':
        return const Color(0xFF4CAF82);
      case 'insurer':
        return const Color(0xFFE07B39);
      case 'vendor':
        return const Color(0xFFFF8C42);
      case 'advisor':
        return const Color(0xFF2196F3);
      case 'logistics':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  List<_TabItem> _tabs(String role) {
    final home = _TabItem(
        icon: Icons.home_rounded, label: 'Home');
    final business = _TabItem(
        icon: Icons.business_center_rounded,
        label: 'Business');
    final loans = _TabItem(
        icon: Icons.account_balance_wallet,
        label: 'Loans');
    final insurance = _TabItem(
        icon: Icons.shield_outlined,
        label: 'Insurance');
    final requests = _TabItem(
        icon: Icons.inbox_rounded, label: 'Requests');
    final orders = _TabItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Orders');
    final products = _TabItem(
        icon: Icons.inventory_2_outlined,
        label: 'Products');
    final sessions = _TabItem(
        icon: Icons.support_agent, label: 'Sessions');
    final shipments = _TabItem(
        icon: Icons.local_shipping_outlined,
        label: 'Shipments');
    final advisory = _TabItem(
        icon: Icons.headset_mic_outlined,
        label: 'My Advisory');
    final inquiriesOut = _TabItem(
        icon: Icons.chat_bubble_outline,
        label: 'My Inquiries');
    final inquiriesIn = _TabItem(
        icon: Icons.forum_outlined,
        label: 'Inquiries');
    final profile = _TabItem(
        icon: Icons.person_outline,
        label: 'My Profile');

    switch (role) {
      case 'lender':
        return [
          home,
          business,
          requests,
          loans,
          insurance,
          orders,
          advisory,
          inquiriesOut,
          profile,
        ];
      case 'insurer':
        return [
          home,
          business,
          requests,
          loans,
          insurance,
          orders,
          advisory,
          inquiriesOut,
          profile,
        ];
      case 'customer':
        return [
          home,
          loans,
          insurance,
          orders,
          advisory,
          inquiriesOut,
          profile,
        ];
      case 'vendor':
        return [
          home,
          business,
          loans,
          insurance,
          products,
          orders,
          advisory,
          inquiriesIn,
          inquiriesOut,
          profile,
        ];
      case 'advisor':
        return [
          home,
          business,
          sessions,
          loans,
          insurance,
          orders,
          profile,
        ];
      case 'logistics':
        // Logistics partners only need their own
        // business profile, their shipments, and
        // their profile page — nothing else.
        return [
          home,
          business,
          shipments,
          profile,
        ];
      default:
        return [home, business, profile];
    }
  }

  int _tabIndex(String label) {
    if (_user == null) return -1;
    final tabs = _tabs(_user!.role);
    return tabs.indexWhere((t) => t.label == label);
  }

  List<Map<String, dynamic>> _getActions(
      BuildContext context) {
    final role = _user?.role ?? '';

    final marketplaceActions = [
      {
        'icon': '🛒',
        'title': 'Browse Products',
        'desc': 'Shop from vendors',
        'onTap': () => context.go('/catalogue'),
      },
      {
        'icon': '📦',
        'title': 'My Orders',
        'desc': 'Track your orders',
        'onTap': () {
          final i = _tabIndex('Orders');
          if (i >= 0) {
            setState(() => _tab = i);
          } else {
            context.go('/my-orders');
          }
        },
      },
      {
        'icon': '💳',
        'title': 'Apply for Loan',
        'desc': 'Browse lenders & apply',
        'onTap': () => context.go('/loan-apply'),
      },
      {
        'icon': '🛡️',
        'title': 'Get Insurance',
        'desc': 'Browse insurers & apply',
        'onTap': () => context.go('/insurance-apply'),
      },
      {
        'icon': '💼',
        'title': 'Get Advice',
        'desc': 'Request advisor session',
        'onTap': () => context.go('/advisory-request'),
      },
    ];

    switch (role) {
      case 'customer':
        return marketplaceActions;

      case 'vendor':
        return [
          {
            'icon': '📦',
            'title': 'My Products',
            'desc': 'Manage your listings',
            'onTap': () {
              final i = _tabIndex('Products');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          {
            'icon': '🏢',
            'title': 'My Business',
            'desc': 'Edit business profile',
            'onTap': () {
              final i = _tabIndex('Business');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          ...marketplaceActions,
        ];

      case 'lender':
        return [
          {
            'icon': '📥',
            'title': 'Loan Requests',
            'desc': 'Review incoming applications',
            'onTap': () {
              final i = _tabIndex('Requests');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          {
            'icon': '🏢',
            'title': 'My Business',
            'desc': 'Edit lender profile',
            'onTap': () {
              final i = _tabIndex('Business');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          ...marketplaceActions,
        ];

      case 'insurer':
        return [
          {
            'icon': '📥',
            'title': 'Insurance Requests',
            'desc': 'Review incoming applications',
            'onTap': () {
              final i = _tabIndex('Requests');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          {
            'icon': '🏢',
            'title': 'My Business',
            'desc': 'Edit insurer profile',
            'onTap': () {
              final i = _tabIndex('Business');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          ...marketplaceActions,
        ];

      case 'advisor':
        return [
          {
            'icon': '📥',
            'title': 'Pending Requests',
            'desc': 'View client requests',
            'onTap': () {
              final i = _tabIndex('Sessions');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          {
            'icon': '🏢',
            'title': 'My Business',
            'desc': 'Edit advisor profile',
            'onTap': () {
              final i = _tabIndex('Business');
              if (i >= 0) setState(() => _tab = i);
            },
          },
        ];

      case 'logistics':
        // Logistics gets ONLY shipment-relevant actions.
        // No marketplace actions of any kind.
        return [
          {
            'icon': '🚚',
            'title': 'My Shipments',
            'desc': 'Manage deliveries',
            'onTap': () {
              final i = _tabIndex('Shipments');
              if (i >= 0) setState(() => _tab = i);
            },
          },
          {
            'icon': '🏢',
            'title': 'My Business',
            'desc': 'Edit logistics profile',
            'onTap': () {
              final i = _tabIndex('Business');
              if (i >= 0) setState(() => _tab = i);
            },
          },
        ];

      default:
        return marketplaceActions;
    }
  }

  Widget _buildPage(String role, String tabLabel) {
    if (_user == null) return const SizedBox();
    switch (tabLabel) {
      case 'Home':
        return _HomeTab(
          user: _user!,
          roleColor: _roleColor(role),
          tabs: _tabs(role),
          actions: _getActions(context),
          onNavigate: (index) =>
              setState(() => _tab = index),
        );
      case 'Business':
        return BusinessProfileScreen(user: _user!);
      case 'Requests':
        return IncomingRequestsScreen(user: _user!);
      case 'Loans':
        return const MyLoansScreen();
      case 'Insurance':
        return const MyInsuranceScreen();
      case 'Orders':
        return const MyOrdersScreen();
      case 'Products':
        return const VendorProductsScreen();
      case 'Sessions':
        return const AdvisorSessionsScreen();
      case 'Shipments':
        return const LogisticsScreen();
      case 'My Advisory':
        return const MyAdvisoryScreen();
      case 'My Inquiries':
        return const BuyerChatsScreen();
      case 'Inquiries':
        return const VendorChatsScreen();
      case 'My Profile':
        return MyProfileScreen(user: _user!);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
            child: CircularProgressIndicator(
                color: Color(0xFF6C63FF))),
      );
    }
    if (_user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Go to Login'),
          ),
        ),
      );
    }

    if (_user!.isBanned) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const Icon(Icons.block,
                  color: Colors.redAccent, size: 56),
              const SizedBox(height: 16),
              const Text('Account Suspended',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              if (_user!.banReason != null)
                Text('Reason: ${_user!.banReason}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white60)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                child: const Text('Sign Out',
                    style:
                        TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        ),
      );
    }

    final role = _user!.role;
    final tabs = _tabs(role);
    final roleColor = _roleColor(role);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Row(
        children: [
          Container(
            width: 220,
            color: const Color(0xFF12121E),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('FinNexus',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                              color: roleColor,
                              letterSpacing: 2)),
                      Container(
                        margin: const EdgeInsets.only(
                            top: 4),
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              roleColor.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                                color: roleColor,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.bold,
                                letterSpacing: 2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: tabs.length,
                    itemBuilder: (context, i) {
                      final item = tabs[i];
                      final isSelected = _tab == i;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _tab = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? roleColor.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(
                                    color: roleColor
                                        .withOpacity(0.4))
                                : null,
                          ),
                          child: Row(children: [
                            Icon(item.icon,
                                color: isSelected
                                    ? roleColor
                                    : Colors.white38,
                                size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(item.label,
                                  style: TextStyle(
                                      color: isSelected
                                          ? roleColor
                                          : Colors.white54,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight
                                              .normal),
                                  overflow:
                                      TextOverflow.ellipsis),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                if (_user!.customerId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        const Text('Customer ID',
                            style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10)),
                        Text(_user!.customerId!,
                            style: TextStyle(
                                color: roleColor,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight:
                                    FontWeight.bold)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () async {
                      await AuthService().signOut();
                      if (mounted) context.go('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent
                                .withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.logout,
                            color: Colors.redAccent,
                            size: 18),
                        SizedBox(width: 10),
                        Text('Sign Out',
                            style: TextStyle(
                                color:
                                    Colors.redAccent)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: _buildPage(role, tabs[_tab].label),
          ),
        ],
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  _TabItem({required this.icon, required this.label});
}

class _HomeTab extends StatelessWidget {
  final UserModel user;
  final Color roleColor;
  final List<_TabItem> tabs;
  final List<Map<String, dynamic>> actions;
  final Function(int) onNavigate;

  const _HomeTab({
    required this.user,
    required this.roleColor,
    required this.tabs,
    required this.actions,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('Welcome back, ${user.businessName}',
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        const Text(
            'Here\'s what you can do on FinNexus today',
            style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 32),
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions.map((action) {
            return GestureDetector(
              onTap: action['onTap'] as VoidCallback,
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                      color: roleColor.withOpacity(0.3)),
                ),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  Text(action['icon'] as String,
                      style:
                          const TextStyle(fontSize: 28)),
                  const SizedBox(height: 12),
                  Text(action['title'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(action['desc'] as String,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12)),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}