import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petut/widgets/custom_button.dart';
import 'package:petut/widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/role_selection');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in error')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _skipLogin() => Navigator.pushReplacementNamed(context, '/main');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
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
                'Sign Up',
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
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter your Email' : null,
                        ),
                        CustomTextField(
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          controller: passwordController,
                          validator: (value) =>
                              value != null && value.length >= 6
                                  ? null
                                  : 'Enter at least 6 characters',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        isLoading
                            ? const CircularProgressIndicator()
                            : CustomButton(
                                text: 'Sign Up',
                                onPressed: _signUp,
                                width: double.infinity,
                                fontSize: 20,
                              ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('or', style: TextStyle(color: textColor)),
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
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account?', style: TextStyle(color: textColor)),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              child: Text(
                                'Log In',
                                style: TextStyle(color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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
    );
  }
}
