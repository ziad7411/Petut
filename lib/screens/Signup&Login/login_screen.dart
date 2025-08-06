import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petut/screens/Signup&Login/auth_helper.dart';
import 'package:petut/widgets/custom_button.dart';
import 'package:petut/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _navigateBasedOnUserState();
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$message ${e.message}")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      await _navigateBasedOnUserState();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google sign-in error')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _navigateBasedOnUserState() async {
    final status = await AuthHelper.checkUserState();

    switch (status) {
      case 'incomplete_form_doctor':
        Navigator.pushReplacementNamed(context, '/doctor_form');
        break;
      case 'incomplete_form_customer':
        Navigator.pushReplacementNamed(context, '/customer_form');
        break;
      case 'doctor_home':
        Navigator.pushReplacementNamed(context, '/goToWebPage');
        break;
      case 'user_home':
        Navigator.pushReplacementNamed(context, '/main');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/start');
        break;
    }
  }

  void _skipLogin() => Navigator.pushReplacementNamed(context, '/main');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: theme.iconTheme.color,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Text(
                  'Log In',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            hintText: 'Email',
                            controller: emailController,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter your Email'
                                        : null,
                          ),
                          CustomTextField(
                            hintText: 'Password',
                            obscureText: _obscurePassword,
                            controller: passwordController,
                            validator:
                                (value) =>
                                    value != null && value.length >= 6
                                        ? null
                                        : 'Enter at least 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/reset_password');
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          isLoading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                text: 'Log In',
                                onPressed: _login,
                                width: double.infinity,
                                fontSize: 20,
                              ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Google',
                            icon: SvgPicture.asset('assets/images/google.svg'),
                            isPrimary: false,
                            width: double.infinity,
                            onPressed: _signInWithGoogle,
                            fontSize: 20,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account?',
                                style: TextStyle(color: textColor),
                              ),
                              TextButton(
                                onPressed:
                                    () =>
                                        Navigator.pushNamed(context, '/signup'),
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                          TextButton(
                            onPressed: _skipLogin,
                            child: Text(
                              'Skip',
                              style: TextStyle(fontSize: 16, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
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
