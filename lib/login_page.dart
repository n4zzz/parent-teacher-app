// lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educonnect/main_menu_page.dart'; // <-- ADD THIS IMPORT (adjust path if needed)


// Enum to represent the active tab/panel
enum ActiveAuthMode { none, signIn, signUp }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // --- Original Design Dimensions (for reference and scaling) ---
  static const double designScreenWidth = 393.0;
  static const double designScreenHeight = 852.0;

  // --- Active Tab State ---
  ActiveAuthMode _activeAuthMode = ActiveAuthMode.none; // Initially no tab is selected

  // --- Colors for active/inactive tabs ---
  static const Color _activeTextColor = Color(0xFF3E3691); // Purple for active text on white box
  static const Color _inactiveTextColorOnDark = Colors.white; // White for inactive text on dark background

  // --- Sign Up Panel State & Controllers ---
  final _fullNameController = TextEditingController();
  final _emailSignUpController = TextEditingController();
  final _passwordSignUpController = TextEditingController();
  bool _isSignUpLoading = false;
  late AnimationController _signUpAnimationController;
  bool _isSignUpPanelVisible = false;
  static const double signUpPanelDesignHeight = 607.0;
  double _signUpPanelClosedPosition = designScreenHeight;
  double _signUpPanelOpenPosition = designScreenHeight - signUpPanelDesignHeight;
  double _currentSignUpPanelPosition = designScreenHeight;

  // --- Sign In Panel State & Controllers ---
  final _emailSignInController = TextEditingController();
  final _passwordSignInController = TextEditingController();
  bool _isSignInLoading = false;
  bool _rememberMe = false;
  late AnimationController _signInAnimationController;
  bool _isSignInPanelVisible = false;
  static const double signInPanelDesignHeight = 594.0;
  double _signInPanelClosedPosition = designScreenHeight;
  double _signInPanelOpenPosition = designScreenHeight - signInPanelDesignHeight;
  double _currentSignInPanelPosition = designScreenHeight;

  // --- Tab Selector Button Original Design Dimensions and Positions ---
  static const double _signInButtonOriginalLeft = 61.0;
  static const double _signInButtonOriginalTop = 802.0;
  static const double _signInButtonOriginalWidth = 66.0;
  static const double _signInButtonOriginalHeight = 32.0;

  static const double _signUpContainerOriginalLeft = 197.0;
  static const double _signUpContainerOriginalTop = 784.0;
  static const double _signUpContainerOriginalWidth = 196.0;
  static const double _signUpContainerOriginalHeight = 68.0;

  double actualScreenWidth = designScreenWidth;
  double actualScreenHeight = designScreenHeight;
  double scaleW = 1.0;
  double scaleH = 1.0;
  double scaleAvg = 1.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _signUpAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _signInAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      actualScreenWidth = MediaQuery.of(context).size.width;
      actualScreenHeight = MediaQuery.of(context).size.height;
      scaleW = actualScreenWidth / designScreenWidth;
      scaleH = actualScreenHeight / designScreenHeight;
      scaleAvg = (scaleW + scaleH) / 2;

      _signUpPanelClosedPosition = actualScreenHeight;
      _signUpPanelOpenPosition = actualScreenHeight - (signUpPanelDesignHeight * scaleH);
      _currentSignUpPanelPosition = _signUpPanelClosedPosition;

      _signInPanelClosedPosition = actualScreenHeight;
      _signInPanelOpenPosition = actualScreenHeight - (signInPanelDesignHeight * scaleH);
      _currentSignInPanelPosition = _signInPanelClosedPosition;

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailSignUpController.dispose();
    _passwordSignUpController.dispose();
    _signUpAnimationController.dispose();
    _emailSignInController.dispose();
    _passwordSignInController.dispose();
    _signInAnimationController.dispose();
    super.dispose();
  }

  void _setActiveMode(ActiveAuthMode mode) {
    if (_activeAuthMode != mode) {
      setState(() { _activeAuthMode = mode; });
    }
  }

  void _toggleSignUpPanel({bool closeOnly = false}) {
    if (!closeOnly && _isSignInPanelVisible) {
      _toggleSignInPanel(closeOnly: true, preserveActiveMode: true); // Preserve mode when auto-closing other panel
    }
    setState(() {
      if (closeOnly || _isSignUpPanelVisible) {
        _currentSignUpPanelPosition = _signUpPanelClosedPosition;
        _isSignUpPanelVisible = false;
        // DO NOT reset _activeAuthMode here if closeOnly is true,
        // it should persist if the panel was closed by back button or drag
      } else {
        _currentSignUpPanelPosition = _signUpPanelOpenPosition;
        _isSignUpPanelVisible = true;
        _setActiveMode(ActiveAuthMode.signUp); // Set active when opening
      }
    });
  }

  void _handleSignUpDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentSignUpPanelPosition += details.delta.dy;
      _currentSignUpPanelPosition = _currentSignUpPanelPosition.clamp(_signUpPanelOpenPosition, _signUpPanelClosedPosition);
    });
  }

  void _handleSignUpDragEnd(DragEndDetails details) {
    bool shouldOpen;
    final scaledPanelHeight = signUpPanelDesignHeight * scaleH;
    if (details.primaryVelocity! > 500) { shouldOpen = false; }
    else if (details.primaryVelocity! < -500) { shouldOpen = true; }
    else { shouldOpen = (_currentSignUpPanelPosition - _signUpPanelOpenPosition) < (scaledPanelHeight * 0.6); }

    _currentSignUpPanelPosition = shouldOpen ? _signUpPanelOpenPosition : _signUpPanelClosedPosition;
    _isSignUpPanelVisible = shouldOpen;

    if (shouldOpen) {
      _setActiveMode(ActiveAuthMode.signUp);
    } else {
      // If dragged closed, _activeAuthMode should remain ActiveAuthMode.signUp
      // No change to _activeAuthMode needed here if it's already correct.
      // It will only change if the other tab is tapped.
    }
    setState(() {});
  }

  Future<void> _performSignUp() async {
    FocusScope.of(context).unfocus();
    if (_fullNameController.text.trim().isEmpty || _emailSignUpController.text.trim().isEmpty || _passwordSignUpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() { _isSignUpLoading = true; });
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailSignUpController.text.trim(), password: _passwordSignUpController.text.trim());
      await userCredential.user?.updateDisplayName(_fullNameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
      _toggleSignUpPanel(closeOnly: true); // Closes panel, _activeAuthMode remains signUp
      _fullNameController.clear(); _emailSignUpController.clear(); _passwordSignUpController.clear();
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'weak-password') message = 'The password is too weak.';
      else if (e.code == 'email-already-in-use') message = 'An account already exists for this email.';
      else if (e.code == 'invalid-email') message = 'The email address is not valid.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() { _isSignUpLoading = false; });
    }
  }

  void _toggleSignInPanel({bool closeOnly = false, bool preserveActiveMode = false}) {
    if (!closeOnly && _isSignUpPanelVisible) {
      _toggleSignUpPanel(closeOnly: true, ); // When Sign In opens, Sign Up closes, its active mode won't be preserved by this call
    }
    setState(() {
      if (closeOnly || _isSignInPanelVisible) {
        _currentSignInPanelPosition = _signInPanelClosedPosition;
        _isSignInPanelVisible = false;
        if (!preserveActiveMode && _activeAuthMode == ActiveAuthMode.signIn) {
          // If we are not preserving, and it was the active one, and now it's closing *not* due to other tab opening
          // then we can set it to none. But the request is for it to "stay". So we don't set to none.
        }
      } else {
        _currentSignInPanelPosition = _signInPanelOpenPosition;
        _isSignInPanelVisible = true;
        _setActiveMode(ActiveAuthMode.signIn); // Set active when opening
      }
    });
  }

  void _handleSignInDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentSignInPanelPosition += details.delta.dy;
      _currentSignInPanelPosition = _currentSignInPanelPosition.clamp(_signInPanelOpenPosition, _signInPanelClosedPosition);
    });
  }

  void _handleSignInDragEnd(DragEndDetails details) {
    bool shouldOpen;
    final scaledPanelHeight = signInPanelDesignHeight * scaleH;
    if (details.primaryVelocity! > 500) { shouldOpen = false; }
    else if (details.primaryVelocity! < -500) { shouldOpen = true; }
    else { shouldOpen = (_currentSignInPanelPosition - _signInPanelOpenPosition) < (scaledPanelHeight * 0.6); }

    _currentSignInPanelPosition = shouldOpen ? _signInPanelOpenPosition : _signInPanelClosedPosition;
    _isSignInPanelVisible = shouldOpen;
    if (shouldOpen) {
      _setActiveMode(ActiveAuthMode.signIn);
    } else {
      // If dragged closed, _activeAuthMode remains ActiveAuthMode.signIn
    }
    setState(() {});
  }

  // Inside _LoginPageState in login_page.dart

  Future<void> _performSignIn() async {
    FocusScope.of(context).unfocus();
    if (_emailSignInController.text.trim().isEmpty || _passwordSignInController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    setState(() { _isSignInLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailSignInController.text.trim(),
        password: _passwordSignInController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Successful!')));
      _toggleSignInPanel(closeOnly: true); // Close panel on success

      // Navigate to MainMenuPage and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainMenuPage()),
            (Route<dynamic> route) => false, // This predicate removes all routes below the new one
      );

      // Optionally clear fields after successful navigation, though less critical now
      // _emailSignInController.clear();
      // _passwordSignInController.clear();

    } on FirebaseAuthException catch (e) {
      String message = "Login Failed.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') { message = "Invalid email or password.";}
      else if (e.code == 'invalid-email') { message = "The email address is not valid.";}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: An unexpected error occurred.')));
    } finally {
      if (mounted) setState(() { _isSignInLoading = false; });
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forgot Password - To be implemented')));
  }

  double responsiveFontSize(double designFontSize) {
    return designFontSize * scaleAvg;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      actualScreenWidth = MediaQuery.of(context).size.width;
      actualScreenHeight = MediaQuery.of(context).size.height;
      scaleW = actualScreenWidth / designScreenWidth;
      scaleH = actualScreenHeight / designScreenHeight;
      scaleAvg = (scaleW + scaleH) / 2;

      _signUpPanelClosedPosition = actualScreenHeight;
      _signUpPanelOpenPosition = actualScreenHeight - (signUpPanelDesignHeight * scaleH);
      if (!_isSignUpPanelVisible) _currentSignUpPanelPosition = _signUpPanelClosedPosition;

      _signInPanelClosedPosition = actualScreenHeight;
      _signInPanelOpenPosition = actualScreenHeight - (signInPanelDesignHeight * scaleH);
      if (!_isSignInPanelVisible) _currentSignInPanelPosition = _signInPanelClosedPosition;
      // _isInitialized = true; // This should be set in didChangeDependencies
    }

    double scaledSignUpContainerWidth = _signUpContainerOriginalWidth * scaleW;
    double scaledSignUpContainerHeight = _signUpContainerOriginalHeight * scaleH;
    double scaledSignUpContainerLeft = _signUpContainerOriginalLeft * scaleW;
    double scaledSignUpContainerTop = _signUpContainerOriginalTop * scaleH;
    double scaledSignInButtonWidth = _signInButtonOriginalWidth * scaleW;
    double scaledSignInButtonLeft = _signInButtonOriginalLeft * scaleW;

    double selectorBoxLeft = scaledSignUpContainerLeft; // Default to sign up visually
    BorderRadius selectorBorderRadius = BorderRadius.only(topLeft: Radius.circular(25 * scaleAvg));
    // The white box should always have the same dimensions as the original _signUpContainer, just its position and border radius change.
    double selectorBoxWidth = scaledSignUpContainerWidth;
    double selectorBoxHeight = scaledSignUpContainerHeight;
    double selectorBoxTop = scaledSignUpContainerTop;


    if (_activeAuthMode == ActiveAuthMode.signIn) {
      selectorBoxLeft = scaledSignInButtonLeft - ((scaledSignUpContainerWidth - scaledSignInButtonWidth) / 2);
      selectorBorderRadius = BorderRadius.only(topRight: Radius.circular(25 * scaleAvg)); // Example change for sign in
    } else if (_activeAuthMode == ActiveAuthMode.signUp) {
      selectorBoxLeft = scaledSignUpContainerLeft;
      selectorBorderRadius = BorderRadius.only(topLeft: Radius.circular(25 * scaleAvg));
    }


    return Scaffold(
      body: SizedBox(
        width: actualScreenWidth,
        height: actualScreenHeight,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.white)),
            Positioned(
              left: 0, top: 0, width: actualScreenWidth, height: actualScreenHeight,
              child: Image.asset('assets/Login_background_bright.png', fit: BoxFit.cover),
            ),
            Positioned(
              left: (97 / designScreenWidth) * actualScreenWidth,
              top: (387 / designScreenHeight) * actualScreenHeight,
              width: (210 / designScreenWidth) * actualScreenWidth,
              child: Text('Welcome', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: responsiveFontSize(40), color: Colors.white)),
            ),

            // Animated Selector White Box
            // It's only visible if a tab has been selected (and remains selected)
            if (_activeAuthMode != ActiveAuthMode.none)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250), // Snappy animation for the box
                curve: Curves.easeInOut,
                left: selectorBoxLeft,
                top: selectorBoxTop,
                width: selectorBoxWidth,
                height: selectorBoxHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), spreadRadius: 4 * scaleAvg, blurRadius: 4 * scaleAvg, offset: Offset(0, -1 * scaleAvg))],
                    borderRadius: selectorBorderRadius,
                  ),
                ),
              ),

            // "Sign in" Button / Tab
            Positioned(
              left: (_signInButtonOriginalLeft / designScreenWidth) * actualScreenWidth,
              top: (_signInButtonOriginalTop / designScreenHeight) * actualScreenHeight,
              width: (_signInButtonOriginalWidth / designScreenWidth) * actualScreenWidth,
              height: (_signInButtonOriginalHeight / designScreenHeight) * actualScreenHeight,
              child: GestureDetector(
                onTap: () => _toggleSignInPanel(),
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    'Sign in',
                    style: TextStyle(
                      fontFamily: 'Hind',
                      fontWeight: FontWeight.w400,
                      fontSize: responsiveFontSize(20),
                      color: _activeAuthMode == ActiveAuthMode.signIn ? _activeTextColor : _inactiveTextColorOnDark,
                    ),
                  ),
                ),
              ),
            ),

            // "Sign up" Button / Tab
            Positioned(
              left: (_signUpContainerOriginalLeft / designScreenWidth) * actualScreenWidth,
              top: (_signUpContainerOriginalTop / designScreenHeight) * actualScreenHeight,
              width: (_signUpContainerOriginalWidth / designScreenWidth) * actualScreenWidth,
              height: (_signUpContainerOriginalHeight / designScreenHeight) * actualScreenHeight,
              child: GestureDetector(
                onTap: () => _toggleSignUpPanel(),
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      fontFamily: 'Hind',
                      fontWeight: FontWeight.w400,
                      fontSize: responsiveFontSize(20),
                      color: _activeAuthMode == ActiveAuthMode.signUp ? _activeTextColor : _inactiveTextColorOnDark,
                    ),
                  ),
                ),
              ),
            ),

            _buildSignInPanel(actualScreenWidth, actualScreenHeight, scaleW, scaleH, scaleAvg),
            _buildSignUpPanel(actualScreenWidth, actualScreenHeight, scaleW, scaleH, scaleAvg),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldContainer({ required TextEditingController controller, required String hintText, bool obscureText = false, TextInputType keyboardType = TextInputType.text, required double scaleAvg}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.15)), borderRadius: BorderRadius.circular(9 * scaleAvg)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.0 * scaleAvg),
        child: TextField(
          controller: controller, obscureText: obscureText, keyboardType: keyboardType,
          style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black),
          decoration: InputDecoration(hintText: hintText, hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black.withOpacity(0.28)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10 * scaleAvg).copyWith(bottom: 12 * scaleAvg)),
        ),
      ),
    );
  }

  Widget _buildSignUpPanel(double acsW, double acsH, double scW, double scH, double scAvg) {
    final scaledPanelHeight = signUpPanelDesignHeight * scH;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, left: 0,
      top: _currentSignUpPanelPosition, width: acsW, height: scaledPanelHeight,
      child: GestureDetector(
        onVerticalDragUpdate: _handleSignUpDragUpdate, onVerticalDragEnd: _handleSignUpDragEnd,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30 * scAvg), topRight: Radius.circular(30 * scAvg))),
          child: Stack(
            children: [
              Positioned(
                left: (acsW - (152 * scW)) / 2, top: 6 * scH, width: 152 * scW, height: 20 * scH,
                child: GestureDetector(
                  onVerticalDragUpdate: _handleSignUpDragUpdate, onVerticalDragEnd: _handleSignUpDragEnd,
                  child: Container(alignment: Alignment.center, color: Colors.transparent, child: Container(width: 152 * scW, height: 6 * scH, decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12 * scAvg)))),
                ),
              ),
              Positioned(
                left: 16 * scW, top: 12 * scH,
                child: TextButton(
                  onPressed: _isSignUpLoading ? null : () => _toggleSignUpPanel(closeOnly: true),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(52 * scW, 24 * scH), alignment: Alignment.centerLeft),
                  child: Text('< Back', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(16), color: Colors.grey[400])),
                ),
              ),
              Positioned(
                left: 0, right: 0, top: 46 * scH,
                child: Text('Get-started', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: responsiveFontSize(32), color: const Color(0xFF3E3691))),
              ),
              Positioned(left: 51 * scW, top: 100 * scH, width: 98 * scW, height: 22 * scH, child: Text('Full name', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black))),
              Positioned(left: 42 * scW, top: 125 * scH, width: 305 * scW, height: 41 * scH, child: _buildTextFieldContainer(controller: _fullNameController, hintText: 'Enter your full name', scaleAvg: scAvg)),
              Positioned(left: 51 * scW, top: (125 + 41 + 10) * scH, width: 98 * scW, height: 22 * scH, child: Text('Email', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black))),
              Positioned(left: 42 * scW, top: (125 + 41 + 10 + 22 + 5) * scH, width: 305 * scW, height: 42 * scH, child: _buildTextFieldContainer(controller: _emailSignUpController, hintText: 'Enter your email', keyboardType: TextInputType.emailAddress, scaleAvg: scAvg)),
              Positioned(left: 51 * scW, top: (125 + 41 + 10 + 22 + 5 + 42 + 10) * scH, width: 98 * scW, height: 21 * scH, child: Text('Password', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black))),
              Positioned(left: 42 * scW, top: (125 + 41 + 10 + 22 + 5 + 42 + 10 + 21 + 5) * scH, width: 305 * scW, height: 42 * scH, child: _buildTextFieldContainer(controller: _passwordSignUpController, hintText: 'Enter your password', obscureText: true, scaleAvg: scAvg)),
              Positioned(
                left: 42 * scW, top: (125 + 41 + 10 + 22 + 5 + 42 + 10 + 21 + 5 + 42 + 30) * scH, width: 305 * scW, height: 50 * scH,
                child: ElevatedButton(
                  onPressed: _isSignUpLoading ? null : _performSignUp,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C84F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scAvg))),
                  child: _isSignUpLoading
                      ? SizedBox(width: 24 * scAvg, height: 24 * scAvg, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Sign up', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(16), color: Colors.white)),
                ),
              ),
              Positioned(
                left:0, right:0, top: (125 + 41 + 10 + 22 + 5 + 42 + 10 + 21 + 5 + 42 + 30 + 50 + 20) * scH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(13), color: Colors.black.withOpacity(0.32))),
                    GestureDetector(
                      onTap: () { if (_isSignUpLoading) return; _toggleSignUpPanel(closeOnly: true); _toggleSignInPanel(); },
                      child: Text('Sign in', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(13), fontWeight: FontWeight.w600, color: const Color(0xFF404FF3))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPanel(double acsW, double acsH, double scW, double scH, double scAvg) {
    final scaledPanelHeight = signInPanelDesignHeight * scH;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, left: 0,
      top: _currentSignInPanelPosition, width: acsW, height: scaledPanelHeight,
      child: GestureDetector(
        onVerticalDragUpdate: _handleSignInDragUpdate, onVerticalDragEnd: _handleSignInDragEnd,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30 * scAvg), topRight: Radius.circular(30 * scAvg))),
          child: Stack(
            children: [
              Positioned(
                left: (acsW - (152 * scW)) / 2, top: 6 * scH, width: 152 * scW, height: 20 * scH,
                child: GestureDetector(
                  onVerticalDragUpdate: _handleSignInDragUpdate, onVerticalDragEnd: _handleSignInDragEnd,
                  child: Container(alignment: Alignment.center, color: Colors.transparent, child: Container(width: 152 * scW, height: 6 * scH, decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12 * scAvg)))),
                ),
              ),
              Positioned(
                left: 16 * scW, top: 12 * scH,
                child: TextButton(
                  onPressed: _isSignInLoading ? null : () => _toggleSignInPanel(closeOnly: true),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(52 * scW, 24 * scH), alignment: Alignment.centerLeft),
                  child: Text('< Back', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(16), color: Colors.grey[400])),
                ),
              ),
              Positioned(
                left: 0, right:0, top: 46 * scH,
                child: Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: responsiveFontSize(32), color: const Color(0xFF3E3691))),
              ),
              Positioned(left: 51 * scW, top: 137 * scH, width: 98 * scW, height: 22 * scH, child: Text('Email', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black))),
              Positioned(left: 42 * scW, top: 159 * scH, width: 305 * scW, height: 42 * scH, child: _buildTextFieldContainer(controller: _emailSignInController, hintText: 'Enter your email', keyboardType: TextInputType.emailAddress, scaleAvg: scAvg)),
              Positioned(left: 51 * scW, top: (159 + 42 + 28) * scH, width: 98 * scW, height: 21 * scH, child: Text('Password', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: Colors.black))),
              Positioned(left: 42 * scW, top: (159 + 42 + 28 + 21 + 5) * scH, width: 305 * scW, height: 42 * scH, child: _buildTextFieldContainer(controller: _passwordSignInController, hintText: 'Enter your password', obscureText: true, scaleAvg: scAvg)),
              Positioned(
                left: 42 * scW, right: 42 * scW, top: (159 + 42 + 28 + 21 + 5 + 42 + 22) * scH, height: 22 * scH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () { setState(() { _rememberMe = !_rememberMe; }); },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 22 * scAvg, height: 22 * scAvg,
                              child: Checkbox(value: _rememberMe, onChanged: (bool? value) { setState(() { _rememberMe = value ?? false; }); }, visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, side: BorderSide(color: Colors.grey[400]!), activeColor: const Color(0xFF4C84F5))),
                          SizedBox(width: 6 * scW),
                          Text('Remember me', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(14), color: const Color(0xFF949191))),
                        ],
                      ),
                    ),
                    GestureDetector(onTap: _handleForgotPassword, child: Text('Forgot password?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: responsiveFontSize(14), color: const Color(0xFF2D50EB)))),
                  ],
                ),
              ),
              Positioned(
                left: 42 * scW, top: (159 + 42 + 28 + 21 + 5 + 42 + 22 + 22 + 30) * scH, width: 305 * scW, height: 50 * scH,
                child: ElevatedButton(
                  onPressed: _isSignInLoading ? null : _performSignIn,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C84F5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scAvg))),
                  child: _isSignInLoading
                      ? SizedBox(width: 24 * scAvg, height: 24 * scAvg, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('Sign in', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(16), color: Colors.white)),
                ),
              ),
              Positioned(
                left: 0, right:0, top: (159 + 42 + 28 + 21 + 5 + 42 + 22 + 22 + 30 + 50 + 38) * scH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(13), color: Colors.black.withOpacity(0.32))),
                    GestureDetector(
                      onTap: () { if (_isSignInLoading) return; _toggleSignInPanel(closeOnly: true); _toggleSignUpPanel(); },
                      child: Text('Sign up', style: TextStyle(fontFamily: 'Poppins', fontSize: responsiveFontSize(13), fontWeight: FontWeight.w600, color: const Color(0xFF404FF3))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}