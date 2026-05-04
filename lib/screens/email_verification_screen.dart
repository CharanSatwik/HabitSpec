import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_glow_button.dart';
import '../utils/ui_utils.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _checkTimer;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start polling for email verification every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.checkEmailVerified();
    });

    // Start cooldown for resend (user just got an email on signup)
    _startResendCooldown();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.sendVerificationEmail();
      if (!mounted) return;
      UIUtils.showTopSnackBar(context, "Verification email sent!");
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      UIUtils.showTopSnackBar(
        context,
        "Failed to send email. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _isChecking = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final verified = await auth.checkEmailVerified();
      if (!mounted) return;
      if (!verified) {
        UIUtils.showTopSnackBar(
          context,
          "Email not yet verified. Please check your inbox.",
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Clean background
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated mail icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      "Verify Your Email",
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We've sent a verification link to",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail ?? "",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    GlassPanel(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Info box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Click the link in your email to verify your account. Check your spam folder too!",
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Manual check button
                          _isChecking
                              ? const SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : PrimaryGlowButton(
                                  text: "I've Verified My Email",
                                  onPressed: _manualCheck,
                                ),
                          const SizedBox(height: 16),

                          // Resend button
                          TextButton.icon(
                            onPressed: (_isResending || _resendCooldown > 0)
                                ? null
                                : _resendEmail,
                            icon: _isResending
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    color: _resendCooldown > 0
                                        ? theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.4)
                                        : theme.colorScheme.primary,
                                    size: 20,
                                  ),
                            label: Text(
                              _resendCooldown > 0
                                  ? "Resend in ${_resendCooldown}s"
                                  : "Resend Verification Email",
                              style: TextStyle(
                                color: _resendCooldown > 0
                                    ? theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.4)
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign out link
                    TextButton(
                      onPressed: () async {
                        final auth =
                            Provider.of<AuthProvider>(context, listen: false);
                        await auth.logout();
                      },
                      child: Text(
                        "Use a different account",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
