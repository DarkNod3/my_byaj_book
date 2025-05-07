import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

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
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Screen states
  // 0: Mobile input, 1: OTP verification, 2: New user name input
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _nameError;
  FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    
    _nameController.addListener(_validateNameField);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    _otpFocusNode.dispose();
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

  void _verifyMobile() {
    if (_formKey.currentState!.validate()) {
      // Hide keyboard before transition
      FocusScope.of(context).unfocus();
      
      // Show loading indicator briefly
      setState(() {
        _isLoading = true;
      });
      
      // Delay to simulate OTP sending
      Future.delayed(const Duration(milliseconds: 800), () {
        _transitionToNextStep();
        setState(() {
          _isLoading = false;
        });
        
        // Focus on OTP field and show keyboard
        Future.delayed(const Duration(milliseconds: 300), () {
          _otpFocusNode.requestFocus();
          
          // Ensure the continue button is visible after focusing on OTP field
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_currentStep == 1) {
              // Scroll to make sure button is visible
              Scrollable.ensureVisible(
                _formKey.currentContext!,
                alignment: 0.8,
                duration: const Duration(milliseconds: 300),
              );
            }
          });
        });
      });
    }
  }

  void _verifyOTP() {
    if (_formKey.currentState!.validate()) {
      if (_otpController.text == '123456') { // Hardcoded test OTP
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        
        // Check if user is new or existing
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.checkUserExists(_mobileController.text).then((exists) {
          if (exists) {
            // Existing user - login and go to home
            userProvider.loginWithMobile(_mobileController.text).then((_) {
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
          } else {
            // New user - request name
            setState(() {
              _isLoading = false;
            });
            _transitionToNextStep();
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    }
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
                  physics: _currentStep == 1 ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
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
        return 'Please enter your mobile number to continue';
      case 1:
        return 'Enter the OTP sent to +91 ${_mobileController.text}';
      case 2:
        return 'Tell us your name to complete registration';
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
        const Text(
          'We\'ll send a 6-digit OTP to verify your number',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationStep() {
    return Column(
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
              onPressed: () {
                // For testing, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test OTP is 123456'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
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
}
