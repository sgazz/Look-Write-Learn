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
  bool isDarkMode = false;
  
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
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }

  void _prevGuide() {
    final String base = _alphabetForMode(guideMode);
    final int idx = base.indexOf(currentGuide);
    final int prev = (idx - 1) < 0 ? base.length - 1 : idx - 1;
    setState(() => currentGuide = base[prev]);
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

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void _pickColor() async {
    final List<Color> palette = <Color>[
      Colors.black,
      Colors.indigo,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.brown,
      Colors.teal,
      Colors.purple,
    ];
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick color'),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final Color c in palette)
                  GestureDetector(
                    onTap: () {
                      setState(() => strokeColor = c);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = isDarkMode || theme.brightness == Brightness.dark;
    
    final TextStyle guideStyle = GoogleFonts.caveat(
      textStyle: TextStyle(
        fontSize: 240,
        color: isDark 
          ? Colors.white.withOpacity(0.2)
          : Colors.grey.withOpacity(0.3),
        fontWeight: FontWeight.w300,
      ),
    );

    return Theme(
      data: isDarkMode 
        ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          )
        : ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LookWriteLearn'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _toggleDarkMode,
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
            ),
          ],
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
                              ),
                              _buildAnimatedButton(
                                onPressed: _nextGuide,
                                icon: Icons.arrow_forward,
                                label: 'Next',
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Third row for mobile
                          Row(
                            children: [
                              const Icon(Icons.brush, size: 20),
                              const SizedBox(width: 8),
                              const Text('Width'),
                              Expanded(
                                child: Slider(
                                  value: strokeWidth,
                                  min: 2,
                                  max: 24,
                                  onChanged: (double v) => setState(() => strokeWidth = v),
                                ),
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
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.brush, size: 20),
                          const SizedBox(width: 8),
                          const Text('Width'),
                          Expanded(
                            child: Slider(
                              value: strokeWidth,
                              min: 2,
                              max: 24,
                              onChanged: (double v) => setState(() => strokeWidth = v),
                            ),
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
            // Bottom actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildAnimatedButton(
                    onPressed: () => DrawingCanvas.clearCanvasNotifier.value = true,
                    icon: Icons.clear,
                    label: 'Clear',
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Practice drawing letters and numbers',
                      textAlign: TextAlign.right,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: () {
              _buttonAnimationController.forward().then((_) {
                _buttonAnimationController.reverse();
              });
              onPressed();
            },
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icon(Icons.text_fields),
              SizedBox(width: 8),
              Text('Uppercase'),
            ],
          ),
        ),
        const PopupMenuItem<GuideMode>(
          value: GuideMode.lower, 
          child: Row(
            children: [
              Icon(Icons.text_fields_outlined),
              SizedBox(width: 8),
              Text('Lowercase'),
            ],
          ),
        ),
        const PopupMenuItem<GuideMode>(
          value: GuideMode.number, 
          child: Row(
            children: [
              Icon(Icons.numbers),
              SizedBox(width: 8),
              Text('Numbers'),
            ],
          ),
        ),
      ],
      child: ElevatedButton.icon(
        onPressed: null,
        icon: Icon(
          switch (guideMode) {
            GuideMode.upper => Icons.text_fields,
            GuideMode.lower => Icons.text_fields_outlined,
            GuideMode.number => Icons.numbers,
          },
        ),
        label: Text(
          switch (guideMode) {
            GuideMode.upper => 'Uppercase',
            GuideMode.lower => 'Lowercase',
            GuideMode.number => 'Numbers',
          },
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

enum GuideMode { upper, lower, number }