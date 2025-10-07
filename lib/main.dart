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

class _PracticeScreenState extends State<PracticeScreen> {
  String currentGuide = 'A';
  GuideMode guideMode = GuideMode.upper;
  Color strokeColor = Colors.indigo;
  double strokeWidth = 8.0;

  void _nextGuide() {
    final String base = _alphabetForMode(guideMode);
    final int idx = base.indexOf(currentGuide);
    final int next = (idx + 1) % base.length;
    setState(() => currentGuide = base[next]);
  }

  void _prevGuide() {
    final String base = _alphabetForMode(guideMode);
    final int idx = base.indexOf(currentGuide);
    final int prev = (idx - 1) < 0 ? base.length - 1 : idx - 1;
    setState(() => currentGuide = base[prev]);
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
    final TextStyle guideStyle = GoogleFonts.caveat(
      textStyle: TextStyle(
        fontSize: 240,
        color: Colors.grey.withOpacity(0.3),
        fontWeight: FontWeight.w300,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('LookWriteLearn'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Controls row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _prevGuide,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Prev'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _nextGuide,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<GuideMode>(
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
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickColor,
                  icon: const Icon(Icons.palette),
                  label: const Text('Color'),
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
                // Model letter as non-interactive overlay
                IgnorePointer(
                  child: Center(
                    child: Text(
                      currentGuide,
                      style: guideStyle,
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
                ElevatedButton.icon(
                  onPressed: () => DrawingCanvas.clearCanvasNotifier.value = true,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
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
    );
  }
}

enum GuideMode { upper, lower, number }


