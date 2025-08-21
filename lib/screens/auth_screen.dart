import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/widgets/common/logo.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:provider/provider.dart';
import 'package:moneymanager/providers/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _TitleSection(),
                const SizedBox(height: 32),
                const AppLogo(),
                const SizedBox(height: 48),
                _GoogleSignInButton(
                  onPressed: () => _handleSignIn(context, scaffoldMessenger),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    ScaffoldMessengerState scaffoldMessenger,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signInWithGoogle();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Money Manager',
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Track your daily expenses and savings',
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: 15,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'Sign in with Google',
      icon: Icons.login,
      onPressed: onPressed,
      type: ButtonType.google,
    );
  }
}
