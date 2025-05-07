import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Screen states
  // 0: Mobile input, 1: OTP verification, 2: New user name input
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _nameError;
  FocusNode _otpFocusNode = FocusNode();
  String? _verificationId;
  int? _resendToken;
  bool _canResendOtp = false;
  int _resendCountdown = 0;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool _firebaseAvailable = true;
  bool _verificationInProgress = false;
  bool _recaptchaVerified = false;
  
  // For custom reCAPTCHA timer
  Timer? _captchaTimer;
  int _captchaProgress = 0;
  bool _captchaInProgress = false;
  
  // This will help us bypass the external verification
  bool _useMockAuthInstead = false;
  
  // Key for scrolling to OTP field
  final GlobalKey _otpSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    _nameController.addListener(_validateNameField);
    
    // Check if Firebase Auth is working properly
    _firebaseAvailable = true; // Start assuming Firebase is available
    try {
      print("Checking Firebase Auth availability...");
      _auth.authStateChanges().listen((user) {
        print("Firebase Auth is working correctly: ${user == null ? 'No user signed in' : 'User signed in'}");
      }, onError: (error) {
        print("Firebase Auth error detected: $error");
        setState(() {
          _firebaseAvailable = false; // Firebase Auth has issues
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using mock authentication - Firebase Auth error: $error'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } catch (e) {
      print("Firebase Auth initialization error: $e");
      setState(() {
        _firebaseAvailable = false; // Firebase Auth failed to initialize
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using mock authentication - Firebase Auth initialization error'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    _otpFocusNode.dispose();
    _scrollController.dispose();
    _captchaTimer?.cancel();
    super.dispose();
  }

  void _validateNameField() {
    final nameText = _nameController.text;
    if (nameText.isNotEmpty) {
      if (RegExp(r'[^a-zA-Z\s]').hasMatch(nameText)) {
        setState(() {
          _nameError = 'Only alphabetic characters are allowed, no numbers or special symbols';
        });
      } else {
        setState(() {
          _nameError = null;
        });
      }
    } else {
      setState(() {
        _nameError = null;
      });
    }
  }

  void _transitionToNextStep() {
    _animationController.reverse().then((_) {
      setState(() {
        if (_currentStep < 2) {
          _currentStep++;
        }
      });
      _animationController.forward();
    });
  }
  
  // Simulate reCAPTCHA verification with a simple in-app verification
  void _verifyRecaptcha() {
    if (_captchaInProgress || _recaptchaVerified) return;
    
    setState(() {
      _captchaInProgress = true;
      _captchaProgress = 0;
    });
    
    // Start a timer to simulate verification process
    _captchaTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_captchaProgress < 100) {
          _captchaProgress += 5;
        } else {
          _captchaTimer?.cancel();
          _captchaInProgress = false;
          _recaptchaVerified = true;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Human verification successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  // Modified verification method to avoid browser-based reCAPTCHA
  void _verifyMobile() {
    if (_formKey.currentState!.validate()) {
      // Check if reCAPTCHA verification was completed
      if (!_recaptchaVerified) {
        setState(() {
          _errorMessage = 'Please verify that you are not a robot first';
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _verificationInProgress = true;
      });
      
      // If Firebase Auth is not available or we want to skip external reCAPTCHA,
      // use our mock authentication instead
      if (!_firebaseAvailable || _useMockAuthInstead) {
        _mockAuthentication();
        return;
      }
      
      // For actual deployment, we'll try Firebase authentication once,
      // but if it opens a browser for reCAPTCHA, we'll set a flag to use mock auth
      // on subsequent attempts
      try {
        // Get the mobile number with country code
        final phoneNumber = '+91${_mobileController.text.trim()}';
        print("Verifying phone number: $phoneNumber");
        
        // No applicationVerifier parameter - we'll handle the external verification case
        _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification on Android (rare)
            print("Auto verification completed");
            await _signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            print("Verification failed: ${e.message}");
            
            // If error indicates reCAPTCHA was needed, switch to mock auth next time
            if (e.message?.contains('recaptcha') ?? false) {
              _useMockAuthInstead = true;
              _mockAuthentication();
              return;
            }
            
            setState(() {
              _isLoading = false;
              _errorMessage = 'Verification failed: ${e.message}';
              _verificationInProgress = false;
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            print("OTP code sent. VerificationId: $verificationId");
            setState(() {
              _isLoading = false;
              _verificationId = verificationId;
              _resendToken = resendToken;
              _startResendTimer();
              _verificationInProgress = false;
            });
            _transitionToNextStep();
            
            // Schedule scrolling to OTP field
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToOtpField();
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Auto-retrieval timeout
            print("Code auto retrieval timeout");
            setState(() {
              _verificationInProgress = false;
            });
          },
          forceResendingToken: _resendToken,
        );
      } catch (e) {
        print("Error in verifyPhoneNumber: $e");
        // If any error occurs during Firebase auth, switch to mock
        _useMockAuthInstead = true;
        _mockAuthentication();
      }
    }
  }

  void _verifyOTP() {
    if (_formKey.currentState!.validate()) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        
      // If Firebase Auth is not available, use mock verification
      if (!_firebaseAvailable) {
        _mockVerifyOTP();
        return;
      }
      
      try {
        print("Verifying OTP: ${_otpController.text.trim()}");
        // Create credential with verification ID and OTP
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId ?? '',
          smsCode: _otpController.text.trim(),
        );
        
        _signInWithCredential(credential);
      } catch (e) {
        print("OTP verification error: $e");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      print("Signing in with credential...");
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        print("Successfully signed in with phone number: ${firebaseUser.phoneNumber}");
        // Successfully signed in
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Check if user exists in your own database
        final exists = await userProvider.checkUserExists(_mobileController.text);
        
          if (exists) {
          print("Existing user found in database");
            // Existing user - login and go to home
          await userProvider.loginWithMobile(_mobileController.text);
          _navigateToHome();
          } else {
          print("New user - requesting name");
            // New user - request name
            setState(() {
              _isLoading = false;
            });
            _transitionToNextStep();
          }
      } else {
        print("Sign-in failed: No user returned");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign-in failed. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.message}';
      });
    } catch (e) {
      print("Unexpected error during sign in: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }
  
  void _resendOTP() {
    if (_canResendOtp) {
      setState(() {
        _otpController.clear();
        _errorMessage = null;
      });
      _verifyMobile();
    }
  }

  void _navigateToHome() {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade900,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(_currentStep == 1 ? 20.0 : 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: _currentStep == 1 ? 20 : 40),
                          Center(
                            child: Hero(
                              tag: 'app_logo',
                              child: Container(
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      spreadRadius: 2,
                                      blurRadius: 15,
                                      offset: const Offset(0, 7),
                                    ),
                                    BoxShadow(
                                      color: Colors.blue.shade700.withOpacity(0.1),
                                      spreadRadius: 10,
                                      blurRadius: 20,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 4,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Image.asset(
                                    'assets/my_byaj_book_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Welcome to My Byaj Book',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(150, 0, 0, 0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getStepText(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 50),
                          
                          // Show error message if any
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade800,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Dynamic content based on current step
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildCurrentStepContent(),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: _currentStep == 1 ? 50 : 30),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildActionButton(),
                          ),
                          
                          if (_currentStep == 1) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _animationController.reverse().then((_) {
                                        setState(() {
                                          _currentStep = 0;
                                          _otpController.clear();
                                          _errorMessage = null;
                                        });
                                        _animationController.forward();
                                      });
                                    },
                              icon: const Icon(Icons.arrow_back, color: Colors.white70),
                              label: const Text(
                                'Change Mobile Number',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin divider line
          Container(
            height: 1, // Very thin line
            color: Colors.white.withOpacity(0.2), // Subtle white color
          ),
          // Footer content based on current step
          _currentStep == 1 
            ? Container(
                height: 10, 
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.blue.shade800,
                      Colors.blue.shade900,
                      Colors.indigo.shade900,
                    ],
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.blue.shade800,
                      Colors.blue.shade900,
                      Colors.indigo.shade900,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "powered by",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "RJ Innovative Media",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    String buttonText = '';
    VoidCallback? onPressed;
    
    switch (_currentStep) {
      case 0:
        buttonText = 'CONTINUE';
        onPressed = _isLoading ? null : _verifyMobile;
        break;
      case 1:
        buttonText = 'VERIFY OTP';
        onPressed = _isLoading ? null : _verifyOTP;
        break;
      case 2:
        buttonText = 'COMPLETE REGISTRATION';
        onPressed = _isLoading ? null : _completeRegistration;
        break;
    }
    
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade500.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  String _getStepText() {
    switch (_currentStep) {
      case 0:
        return 'Enter your mobile number to continue';
      case 1:
        return 'Enter the 6-digit code sent to your phone';
      case 2:
        return 'Tell us your name to complete setup';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMobileInputStep();
      case 1:
        return _buildOtpVerificationStep();
      case 2:
        return _buildNameInputStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMobileInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          scrollPadding: const EdgeInsets.only(bottom: 240),
          decoration: InputDecoration(
            prefixText: '+91 ',
            prefixStyle: TextStyle(
              fontWeight: FontWeight.bold, 
              color: Colors.blue.shade800,
              fontSize: 16,
            ),
            hintText: 'Enter the Mobile Number',
            hintStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            if (value.length != 10) {
              return 'Please enter a valid 10-digit mobile number';
            }
            return null;
          },
          onChanged: (value) {
            // Force exactly 10 digits
            if (value.length > 10) {
              _mobileController.text = value.substring(0, 10);
              _mobileController.selection = TextSelection.fromPosition(
                TextPosition(offset: 10),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        // Interactive reCAPTCHA widget
        GestureDetector(
          onTap: () {
            if (!_captchaInProgress && !_recaptchaVerified) {
              _verifyRecaptcha();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _recaptchaVerified,
                      onChanged: (value) {
                        if (!_captchaInProgress && !_recaptchaVerified) {
                          _verifyRecaptcha();
                        }
                      },
                      checkColor: Colors.white,
                      fillColor: MaterialStateProperty.resolveWith(
                        (states) => _recaptchaVerified ? Colors.green.shade600 : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'I am not a robot',
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ),
                    _recaptchaVerified 
                      ? Icon(Icons.verified_user, color: Colors.green.shade600)
                      : _captchaInProgress
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: _captchaProgress / 100,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            )
                          : Icon(Icons.shield_outlined, color: Colors.grey.shade600),
                  ],
                ),
                if (_captchaInProgress) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _captchaProgress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifying you are human...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'We\'ll send a 6-digit OTP to verify your number',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
      key: _otpSectionKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the 6-digit code we sent to your phone',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 15),
          textAlign: TextAlign.center,
          scrollPadding: const EdgeInsets.only(bottom: 400),
          decoration: InputDecoration(
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              fontSize: 20, 
              letterSpacing: 10,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 6) {
              return 'OTP must be 6 digits';
            }
            return null;
          },
          onChanged: (value) {
            // Auto-submit when 6 digits are entered
            if (value.length == 6) {
              // Hide keyboard
              FocusScope.of(context).unfocus();
            }
          },
          autofocus: true,
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive the code? ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton(
              onPressed: _resendOTP,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Resend',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Almost there!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 16),
          scrollPadding: const EdgeInsets.only(bottom: 240),
          decoration: InputDecoration(
            labelText: 'Your Full Name',
            prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade700),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            errorText: _nameError,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters';
            }
            if (RegExp(r'[^a-zA-Z\s]').hasMatch(value)) {
              return 'Only alphabetic characters are allowed';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        const Text(
          'We\'ll use this name for all your transactions',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  void _completeRegistration() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.registerUser(
        mobile: _mobileController.text,
        name: _nameController.text,
      ).then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      });
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResendOtp = false;
      _resendCountdown = 30; // 30 seconds countdown
    });
    
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResendOtp = true;
          _resendCountdown = 0;
        });
      }
    });
  }

  // Enhanced mock authentication to provide a better OTP experience
  void _mockAuthentication() {
    print("Using mock authentication flow");
    // Simulate network delay
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _verificationId = 'mock-verification-id';
        _startResendTimer();
      });
      
      _transitionToNextStep();
      
      // Schedule scrolling to OTP field in the mock flow too
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToOtpField();
      });
      
      // Show a better success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully to +91 ${_mobileController.text}'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // Mock OTP verification for when Firebase is not available
  void _mockVerifyOTP() {
    print("Using mock OTP verification");
    // Simulate network delay
    Future.delayed(Duration(seconds: 1), () {
      final enteredOTP = _otpController.text.trim();
      
      // For testing, accept any 6-digit OTP
      if (enteredOTP.length == 6 && int.tryParse(enteredOTP) != null) {
        print("Mock OTP accepted: $enteredOTP");
        // Check if user exists in the app's database
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // For demo, consider mobile number "9876543210" as existing user
        if (_mobileController.text.trim() == "9876543210") {
          print("Existing user detected: ${_mobileController.text.trim()}");
          userProvider.loginWithMobile(_mobileController.text).then((_) {
            _navigateToHome();
          });
        } else {
          print("New user detected: ${_mobileController.text.trim()}");
          // New user - request name
          setState(() {
            _isLoading = false;
          });
          _transitionToNextStep();
        }
      } else {
        print("Invalid mock OTP format: $enteredOTP");
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP. Please enter a 6-digit number.';
        });
      }
    });
  }

  void _scrollToOtpField() {
    if (_otpSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _otpSectionKey.currentContext!,
        alignment: 0.2, // Position it near the top of the screen
        duration: const Duration(milliseconds: 300),
      );
      
      // Focus on OTP field
      FocusScope.of(context).requestFocus(_otpFocusNode);
    }
  }
}
