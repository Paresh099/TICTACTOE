import 'package:flutter/material.dart';
import 'dart:async';
import 'offline_game.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _rotationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _startAnimations();
    _navigateToHome();
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(Duration(milliseconds: 800));
    _textController.forward();

    _rotationController.repeat();
  }

  void _navigateToHome() {
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => OfflineGame(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Widget _buildTicTacToeGrid() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGridCell('X', Colors.blue.shade300)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('', Colors.white)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('O', Colors.red.shade300)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGridCell('', Colors.white)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('X', Colors.blue.shade300)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('', Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGridCell('O', Colors.red.shade300)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('', Colors.white)),
                  SizedBox(width: 8),
                  Expanded(child: _buildGridCell('X', Colors.blue.shade300)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCell(String symbol, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: symbol.isNotEmpty ? _rotationAnimation.value * 0.3 : 0,
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Tic Tac Toe Grid Logo
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: _buildTicTacToeGrid(),
                  );
                },
              ),

              SizedBox(height: 40),

              // Animated Title
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - _textAnimation.value)),
                      child: Column(
                        children: [
                          Text(
                            'TIC TAC TOE',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: Offset(2, 2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Challenge Your Mind',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 60),

              // Loading Indicator
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textAnimation.value,
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loading Game...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}