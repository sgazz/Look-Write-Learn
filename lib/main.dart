import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/drawing_canvas.dart';

void main() {
  runApp(const LookWriteLearnApp());
}

class LookWriteLearnApp extends StatelessWidget {
  const LookWriteLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LookWriteLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PracticeScreen(),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with TickerProviderStateMixin {
  String currentGuide = 'A';
  GuideMode guideMode = GuideMode.upper;
  Color strokeColor = Colors.indigo;
  double strokeWidth = 8.0;
  
  late AnimationController _letterAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _letterScaleAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _letterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _letterScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _letterAnimationController.forward();
  }

  @override
  void dispose() {
    _letterAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _nextGuide() {
    final String base = _alphabetForMode(guideMode);
    final int idx = base.indexOf(currentGuide);
    final int next = (idx + 1) % base.length;
    setState(() => currentGuide = base[next]);
    // Clear canvas when changing to next letter
    DrawingCanvas.clearCanvasNotifier.value = true;
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }

  void _prevGuide() {
    final String base = _alphabetForMode(guideMode);
    final int idx = base.indexOf(currentGuide);
    final int prev = (idx - 1) < 0 ? base.length - 1 : idx - 1;
    setState(() => currentGuide = base[prev]);
    // Clear canvas when changing to previous letter
    DrawingCanvas.clearCanvasNotifier.value = true;
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }

  String _alphabetForMode(GuideMode mode) {
    switch (mode) {
      case GuideMode.upper:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case GuideMode.lower:
        return 'abcdefghijklmnopqrstuvwxyz';
      case GuideMode.number:
        return '0123456789';
    }
  }

  void _setMode(GuideMode mode) {
    if (guideMode == mode) return;
    setState(() {
      guideMode = mode;
      currentGuide = _alphabetForMode(guideMode).characters.first;
    });
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }


  void _pickColor() async {
    final List<Color> palette = <Color>[
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.palette, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Choose Your Color! 🌈'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pick your favorite color to draw with!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final Color c in palette)
                      GestureDetector(
                        onTap: () {
                          setState(() => strokeColor = c);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: strokeColor == c ? Colors.white : Colors.black26,
                              width: strokeColor == c ? 3 : 1,
                            ),
                            boxShadow: strokeColor == c
                                ? [
                                    BoxShadow(
                                      color: c.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: strokeColor == c
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle guideStyle = GoogleFonts.caveat(
      textStyle: TextStyle(
        fontSize: 240,
        color: Colors.grey.withOpacity(0.3),
        fontWeight: FontWeight.w300,
      ),
    );

    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // L - Pink with fun font
              Text(
                'L',
                style: GoogleFonts.comicNeue(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                  shadows: [
                    Shadow(
                      color: Colors.pink.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // o - Orange with fun font
              Text(
                'o',
                style: GoogleFonts.comicNeue(
                  fontSize: 26,
                  color: Colors.orange,
                  shadows: [
                    Shadow(
                      color: Colors.orange.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // o - Yellow with fun font
              Text(
                'o',
                style: GoogleFonts.comicNeue(
                  fontSize: 30,
                  color: Colors.yellow.shade700,
                  shadows: [
                    Shadow(
                      color: Colors.yellow.shade400,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // k - Green with fun font
              Text(
                'k',
                style: GoogleFonts.comicNeue(
                  fontSize: 28,
                  color: Colors.green,
                  shadows: [
                    Shadow(
                      color: Colors.green.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // W - Blue with fun font
              Text(
                'W',
                style: GoogleFonts.comicNeue(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  shadows: [
                    Shadow(
                      color: Colors.blue.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // r - Purple with fun font
              Text(
                'r',
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  color: Colors.purple,
                  shadows: [
                    Shadow(
                      color: Colors.purple.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // i - Red with fun font
              Text(
                'i',
                style: GoogleFonts.caveat(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  shadows: [
                    Shadow(
                      color: Colors.red.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // t - Teal with fun font
              Text(
                't',
                style: GoogleFonts.comicNeue(
                  fontSize: 26,
                  color: Colors.teal,
                  shadows: [
                    Shadow(
                      color: Colors.teal.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // e - Indigo with fun font
              Text(
                'e',
                style: GoogleFonts.comicNeue(
                  fontSize: 28,
                  color: Colors.indigo,
                  shadows: [
                    Shadow(
                      color: Colors.indigo.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // L - Pink with fun font
              Text(
                'L',
                style: GoogleFonts.comicNeue(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                  shadows: [
                    Shadow(
                      color: Colors.pink.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // e - Orange with fun font
              Text(
                'e',
                style: GoogleFonts.comicNeue(
                  fontSize: 26,
                  color: Colors.orange,
                  shadows: [
                    Shadow(
                      color: Colors.orange.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // a - Yellow with fun font
              Text(
                'a',
                style: GoogleFonts.comicNeue(
                  fontSize: 30,
                  color: Colors.yellow.shade700,
                  shadows: [
                    Shadow(
                      color: Colors.yellow.shade400,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // r - Green with fun font
              Text(
                'r',
                style: GoogleFonts.comicNeue(
                  fontSize: 28,
                  color: Colors.green,
                  shadows: [
                    Shadow(
                      color: Colors.green.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              // n - Blue with fun font
              Text(
                'n',
                style: GoogleFonts.comicNeue(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  shadows: [
                    Shadow(
                      color: Colors.blue.shade300,
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.deepPurple,
          elevation: 8,
          shadowColor: Colors.orange.withOpacity(0.3),
        ),
        body: Column(
          children: [
            // Controls row - responsive design
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return isMobile 
                    ? Column(
                        children: [
                          // First row for mobile
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                            _buildAnimatedButton(
                              onPressed: _prevGuide,
                              icon: Icons.arrow_back,
                              label: 'Prev',
                              backgroundColor: Colors.blue,
                            ),
                            _buildAnimatedButton(
                              onPressed: _nextGuide,
                              icon: Icons.arrow_forward,
                              label: 'Next',
                              backgroundColor: Colors.green,
                            ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Second row for mobile
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildModeSelector(),
                              _buildAnimatedButton(
                                onPressed: _pickColor,
                                icon: Icons.palette,
                                label: 'Color',
                                backgroundColor: Colors.purple,
                              ),
                              _buildAnimatedButton(
                                onPressed: () => DrawingCanvas.undoNotifier.value = true,
                                icon: Icons.undo,
                                label: 'Undo',
                                backgroundColor: Colors.orange,
                              ),
                              _buildAnimatedButton(
                                onPressed: () => DrawingCanvas.redoNotifier.value = true,
                                icon: Icons.redo,
                                label: 'Redo',
                                backgroundColor: Colors.teal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Third row for mobile - Clear button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAnimatedButton(
                                onPressed: () => DrawingCanvas.clearCanvasNotifier.value = true,
                                icon: Icons.auto_fix_high,
                                label: 'Clear',
                                backgroundColor: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildAnimatedButton(
                            onPressed: _prevGuide,
                            icon: Icons.arrow_back,
                            label: 'Prev',
                          ),
                          const SizedBox(width: 8),
                          _buildAnimatedButton(
                            onPressed: _nextGuide,
                            icon: Icons.arrow_forward,
                            label: 'Next',
                          ),
                          const SizedBox(width: 16),
                          _buildModeSelector(),
                          const SizedBox(width: 16),
                        _buildAnimatedButton(
                          onPressed: _pickColor,
                          icon: Icons.palette,
                          label: 'Color',
                          backgroundColor: Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        _buildAnimatedButton(
                          onPressed: () => DrawingCanvas.undoNotifier.value = true,
                          icon: Icons.undo,
                          label: 'Undo',
                          backgroundColor: Colors.orange,
                        ),
                        _buildAnimatedButton(
                          onPressed: () => DrawingCanvas.redoNotifier.value = true,
                          icon: Icons.redo,
                          label: 'Redo',
                          backgroundColor: Colors.teal,
                        ),
                        const SizedBox(width: 16),
                        _buildAnimatedButton(
                          onPressed: () => DrawingCanvas.clearCanvasNotifier.value = true,
                          icon: Icons.auto_fix_high,
                          label: 'Clear',
                          backgroundColor: Colors.red,
                        ),
                        ],
                      );
                },
              ),
            ),
            // Canvas area with guide letter
            Expanded(
              child: Stack(
                children: [
          DrawingCanvas(
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            onClearRequested: () {},
          ),
                  // Model letter as non-interactive overlay with animation
                  IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _letterScaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _letterScaleAnimation.value,
                            child: Text(
                              currentGuide,
                              style: guideStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
  }) {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Tooltip(
            message: label,
            child: ElevatedButton(
              onPressed: () {
                _buttonAnimationController.forward().then((_) {
                  _buttonAnimationController.reverse();
                });
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                backgroundColor: backgroundColor,
                foregroundColor: backgroundColor != null ? Colors.white : null,
                elevation: 4,
                shadowColor: backgroundColor?.withOpacity(0.3),
                shape: const CircleBorder(),
              ),
              child: Icon(icon, size: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return PopupMenuButton<GuideMode>(
      initialValue: guideMode,
      onSelected: _setMode,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<GuideMode>>[
        const PopupMenuItem<GuideMode>(
          value: GuideMode.upper, 
          child: Row(
            children: [
              Icon(Icons.text_fields, color: Colors.blue),
              SizedBox(width: 8),
              Text('A B C'),
            ],
          ),
        ),
        const PopupMenuItem<GuideMode>(
          value: GuideMode.lower, 
          child: Row(
            children: [
              Icon(Icons.text_fields_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('a b c'),
            ],
          ),
        ),
        const PopupMenuItem<GuideMode>(
          value: GuideMode.number, 
          child: Row(
            children: [
              Icon(Icons.numbers, color: Colors.orange),
              SizedBox(width: 8),
              Text('1 2 3'),
            ],
          ),
        ),
      ],
      child: Tooltip(
        message: switch (guideMode) {
          GuideMode.upper => 'Uppercase Letters',
          GuideMode.lower => 'Lowercase Letters', 
          GuideMode.number => 'Numbers',
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: switch (guideMode) {
              GuideMode.upper => Colors.blue.withOpacity(0.1),
              GuideMode.lower => Colors.green.withOpacity(0.1),
              GuideMode.number => Colors.orange.withOpacity(0.1),
            },
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: switch (guideMode) {
                GuideMode.upper => Colors.blue,
                GuideMode.lower => Colors.green,
                GuideMode.number => Colors.orange,
              },
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (guideMode) {
                  GuideMode.upper => Icons.text_fields,
                  GuideMode.lower => Icons.text_fields_outlined,
                  GuideMode.number => Icons.numbers,
                },
                color: switch (guideMode) {
                  GuideMode.upper => Colors.blue,
                  GuideMode.lower => Colors.green,
                  GuideMode.number => Colors.orange,
                },
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                switch (guideMode) {
                  GuideMode.upper => 'A B C',
                  GuideMode.lower => 'a b c',
                  GuideMode.number => '1 2 3',
                },
                style: TextStyle(
                  color: switch (guideMode) {
                    GuideMode.upper => Colors.blue,
                    GuideMode.lower => Colors.green,
                    GuideMode.number => Colors.orange,
                  },
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum GuideMode { upper, lower, number }