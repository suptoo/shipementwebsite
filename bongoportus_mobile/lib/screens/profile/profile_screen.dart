import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return _buildUnauthenticated(context);
        }
        return _buildAuthenticated(context, auth);
      },
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withAlpha(20),
                          AppTheme.primaryColor.withAlpha(8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withAlpha(25),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome to\nBongoPortus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppTheme.secondaryColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to manage orders,\nmessages, and your profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticated(BuildContext context, AuthProvider auth) {
    final profile = auth.profile!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium gradient header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.darkGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative floating circles
                  Positioned(
                    top: -20,
                    right: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(6),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profile',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    context.push('/profile/edit'),
                                icon: const Icon(Icons.edit_rounded,
                                    color: Colors.white70, size: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Avatar with gradient border
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLight,
                                  Colors.white.withAlpha(60),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor:
                                  AppTheme.primaryColor.withAlpha(40),
                              backgroundImage: profile.avatarUrl != null
                                  ? NetworkImage(profile.avatarUrl!)
                                  : null,
                              child: profile.avatarUrl == null
                                  ? Text(
                                      profile.displayName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 14,
                            ),
                          ),
                          if (profile.role != 'user') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(40),
                                ),
                              ),
                              child: Text(
                                profile.role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                          // Stats row
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.shopping_bag_rounded,
                                        color: Colors.white.withAlpha(140),
                                        size: 18),
                                    const SizedBox(height: 4),
                                    const Text('-',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                    Text('Orders',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withAlpha(120),
                                            fontSize: 10)),
                                  ],
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.white.withAlpha(25),
                                ),
                                Column(
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        color: Colors.white.withAlpha(140),
                                        size: 18),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.createdAt != null
                                          ? '${DateTime.tryParse(profile.createdAt!)?.year ?? '-'}'
                                          : '-',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text('Member since',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withAlpha(120),
                                            fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu sections ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('Account', [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    color: AppTheme.infoColor,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Addresses',
                    color: AppTheme.successColor,
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  _MenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'My Orders',
                    color: AppTheme.warningColor,
                    onTap: () => context.go('/orders'),
                  ),
                ]),
                const SizedBox(height: 20),

                _buildSection('Communication', [
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Messages',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/messages'),
                  ),
                  _MenuItem(
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Support',
                    color: AppTheme.primaryColor,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 20),

                _buildSection('Settings', [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    color: AppTheme.errorColor,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'English',
                    color: AppTheme.infoColor,
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 28),

                // Sign out
                _buildSignOutButton(context, auth),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'BongoPortus v1.0.0',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB0B7C3),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.cardElevation,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final item = entry.value;
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: entry.key == 0
                          ? const Radius.circular(18)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(18)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.color.withAlpha(18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon,
                                color: item.color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.grey.shade300, size: 22),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 70,
                      color: Colors.grey.shade100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, auth),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: BorderSide(color: AppTheme.errorColor.withAlpha(50)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppTheme.errorColor.withAlpha(6),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.errorColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign Out?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out of your account?',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        auth.signOut();
                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });
}
