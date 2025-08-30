import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final neonGreen = const Color(0xFF00FF88);
    final darkBg = const Color(0xFF0B0F13);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Traffic Sign Detector',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonGreen,
          brightness: Brightness.dark,
          primary: neonGreen,
          secondary: neonGreen,
          surface: darkBg,
        ),
        textTheme: GoogleFonts.orbitronTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: neonGreen, displayColor: neonGreen),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBg.withAlpha(170),
          elevation: 0,
          titleTextStyle: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: neonGreen,
            letterSpacing: 2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style:
              ElevatedButton.styleFrom(
                foregroundColor: darkBg,
                backgroundColor: neonGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                textStyle: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).merge(
                ButtonStyle(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.pressed)
                        ? neonGreen.withAlpha(51)
                        : null,
                  ),
                ),
              ),
        ),
      ),
      home: const FuturisticHome(),
    );
  }
}

class FuturisticHome extends StatefulWidget {
  const FuturisticHome({super.key});

  @override
  State<FuturisticHome> createState() => _FuturisticHomeState();
}

class _FuturisticHomeState extends State<FuturisticHome> {
  bool _initializingCamera = false;
  bool _detecting = false;
  String? _error;

  Future<void> _start() async {
    if (_detecting || _initializingCamera) return;
    setState(() {
      _initializingCamera = true;
      _error = null;
    });
    try {
      // YOLOView handles camera internally, so we just need to set the state
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Small delay for UI
      if (!mounted) return;
      setState(() {
        _detecting = true;
      });
    } catch (e) {
      setState(() => _error = 'Detection error: $e');
    } finally {
      if (mounted) {
        setState(() => _initializingCamera = false);
      }
    }
  }

  Future<void> _stop() async {
    setState(() {
      _detecting = false;
    });
    // YOLOView handles camera disposal internally
  }

  @override
  void dispose() {
    // YOLOView handles camera disposal internally
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final neonGreen = theme.colorScheme.primary;
    return Scaffold(
      body: Stack(
        children: [
          // Global background scan grid overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(color: neonGreen.withAlpha(40)),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isVertical =
                  constraints.maxWidth < 900; // stack on small screens
              final leftWidth = isVertical
                  ? constraints.maxWidth
                  : constraints.maxWidth / 2;
              final rightWidth = isVertical
                  ? constraints.maxWidth
                  : constraints.maxWidth / 2;

              final preview = Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: neonGreen.withAlpha(170),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withAlpha(51),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_detecting)
                          YOLOView(
                            modelPath: 'yolo11n',
                            task: YOLOTask.detect,
                            onResult: (results) {
                              print('Found ${results.length} objects!');
                              for (final result in results) {
                                print(
                                  '${result.className}: ${result.confidence}',
                                );
                              }
                            },
                          )
                        else
                          Container(
                            alignment: Alignment.center,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: _initializingCamera ? 1 : 0.7,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_initializingCamera)
                                    const SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  if (_initializingCamera)
                                    const SizedBox(height: 20),
                                  Text(
                                    _error ?? 'LIVE FEED',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          letterSpacing: 4,
                                          fontWeight: FontWeight.w700,
                                          color: _error != null
                                              ? Colors.redAccent
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CornerBracketsPainter(
                                color: neonGreen.withAlpha(230),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final controls = Container(
                width: rightWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(10),
                      Colors.white.withAlpha(2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    left: isVertical
                        ? BorderSide.none
                        : BorderSide(color: neonGreen.withAlpha(170), width: 1),
                    top: isVertical
                        ? BorderSide(color: neonGreen.withAlpha(51), width: 1)
                        : BorderSide.none,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: !_detecting
                      ? Column(
                          key: const ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'TRAFFIC SIGN DETECTOR',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(
                                    color: neonGreen.withAlpha(170),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            _GlowButton(
                              label: 'START',
                              icon: Icons.play_arrow,
                              onPressed: _start,
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('detecting'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(strokeWidth: 4),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'DETECTING...',
                              style: theme.textTheme.titleLarge?.copyWith(
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _GlowButton(
                              label: 'STOP',
                              icon: Icons.stop,
                              onPressed: _stop,
                            ),
                          ],
                        ),
                ),
              );

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isVertical
                    ? SingleChildScrollView(
                        key: const ValueKey('vertical'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        child: SafeArea(
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: Column(
                              children: [
                                SizedBox(width: leftWidth, child: preview),
                                const SizedBox(height: 56),
                                controls,
                              ],
                            ),
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('horizontal'),
                        children: [
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: leftWidth * 0.9,
                                child: preview,
                              ),
                            ),
                          ),
                          SizedBox(width: rightWidth, child: controls),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _GlowButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final neonGreen = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: neonGreen.withAlpha(51),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const grid = 20.0;
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  _CornerBracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bracket = Path();
    const corner = 28.0;
    const len = 46.0;
    void addCorner(bool right, bool bottom) {
      final ox = right ? size.width - corner : corner;
      final oy = bottom ? size.height - corner : corner;
      final dirX = right ? -1 : 1;
      final dirY = bottom ? -1 : 1;
      bracket.moveTo(ox + len * dirX, oy);
      bracket.lineTo(ox, oy);
      bracket.lineTo(ox, oy + len * dirY);
    }

    addCorner(false, false);
    addCorner(true, false);
    addCorner(false, true);
    addCorner(true, true);
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(bracket, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
