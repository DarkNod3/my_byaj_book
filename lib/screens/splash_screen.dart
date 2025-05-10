import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize the UserProvider with timeout
    _initializeApp();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }
  
  Future<void> _initializeApp() async {
    // Initialize the UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Create a timeout to ensure app doesn't get stuck
    bool isInitialized = false;
    
    try {
      // Try to initialize user provider with a timeout
      await Future.any([
        // Normal initialization
        userProvider.initialize().then((_) {
          isInitialized = true;
          debugPrint('User provider initialized successfully');
        }),
        
        // Timeout after 3 seconds
        Future.delayed(const Duration(seconds: 3)).then((_) {
          if (!isInitialized) {
            debugPrint('User provider initialization timed out');
          }
        }),
      ]);
    } catch (e) {
      debugPrint('Error initializing user provider: $e');
    } finally {
      // Navigate to next screen after a delay regardless of initialization status
      Future.delayed(const Duration(milliseconds: 3000), () {
        _checkUserAndNavigate();
      });
    }
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // The initialize method was called in initState, so user data should be loaded
      final user = userProvider.user;
      
      // Add debug print to see what's happening
      debugPrint('Splash screen navigation check: user = $user');
      
      // Force navigation to login if initialization takes too long
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation1, animation2) => 
            user != null ? const HomeScreen() : const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in splash screen navigation: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Force navigation to login screen if there's an error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For responsive sizing
    final Size size = MediaQuery.of(context).size;
    
    return Scaffold(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            height: size.width * 0.45,
                            width: size.width * 0.45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(38),
                                  spreadRadius: 2,
                                  blurRadius: 15,
                                  offset: const Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: Colors.blue.shade700.withAlpha(26),
                                  spreadRadius: 10,
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withAlpha(230),
                                width: 4,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withAlpha(230),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/my_byaj_book_logo.png',
                                fit: BoxFit.contain,
                                width: size.width * 0.35,
                                height: size.width * 0.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Name
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          'My Byaj Book',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                offset: const Offset(2, 2),
                                blurRadius: 3.0,
                                color: Colors.black.withAlpha(77),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Hindi Text (Meaning "Simplify Your Accounting" in Hindi)
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: Text(
                      'आपके हिसाब-किताब को आसान बनाए',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Loading indicator
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withAlpha(230),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      "powered by",
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
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
            ),
          ],
        ),
      ),
    );
  }
}
