import 'package:flutter/material.dart';

import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/data/models/auth_session.dart';
import 'registration_page.dart';
import 'sign_in_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    required this.onAuthenticated,
    super.key,
  });

  final Future<void> Function(AuthSession) onAuthenticated;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              visuals.bright,
              visuals.primary,
              visuals.deep,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: AspectRatio(
                        aspectRatio: 0.76,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(34),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: _WelcomeArtwork(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.text('welcomeTitle'),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.text('welcomeSubtitle'),
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFCE7F0),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RegistrationPage(
                            onAuthenticated: onAuthenticated,
                          ),
                        ),
                      );
                    },
                    child: Text(strings.text('signUp')),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SignInPage(
                            onAuthenticated: onAuthenticated,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(strings.text('signIn')),
                  ),
                ),
      
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showBackendServerDialog(BuildContext context) async {
  final settings = AppSettingsScope.readControllerOf(context);
  final strings = AppSettingsScope.readStringsOf(context);
  final visuals = context.appVisuals;
  final controller = TextEditingController(text: settings.backendUrl);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(strings.text('backendServerTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.text('backendServerSubtitle'),
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                color: visuals.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: strings.text('backendUrlLabel'),
                hintText: strings.text('backendUrlHint'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.text('backendWifiHelp'),
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: visuals.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await settings.setBackendUrl(controller.text);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(content: Text(strings.text('backendUrlSaved'))),
                );
              } on FormatException {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(content: Text(strings.text('backendUrlInvalid'))),
                );
              }
            },
            child: Text(strings.text('saveBackendUrl')),
          ),
        ],
      );
    },
  );

  controller.dispose();
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork();

  @override
  Widget build(BuildContext context) {
    final visuals = context.appVisuals;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  visuals.bright.withValues(alpha: 0.96),
                  visuals.primary.withValues(alpha: 0.88),
                  visuals.deep.withValues(alpha: 0.96),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 310,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppPalette.softShell,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(170),
                  bottomRight: Radius.circular(170),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 38,
          left: 44,
          right: 44,
          child: Column(
            children: const [
              _SafetyScene(),
              SizedBox(height: 18),
              _InfinityBadge(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyScene extends StatelessWidget {
  const _SafetyScene();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: _HeartMoon(),
          ),
          const Positioned(
            top: 66,
            left: 94,
            right: 94,
            child: _SafetyTree(),
          ),
          const Positioned(
            left: 2,
            top: 92,
            child: _PersonCluster(direction: Axis.horizontal),
          ),
          const Positioned(
            right: 2,
            top: 104,
            child: _PersonCluster(direction: Axis.horizontal, mirrored: true),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 108,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppPalette.darkPlum,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppPalette.darkPlum.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartMoon extends StatelessWidget {
  const _HeartMoon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const _HeartShape(width: 132, height: 118),
        ],
      ),
    );
  }
}

class _HeartShape extends StatelessWidget {
  const _HeartShape({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _HeartPainter()),
    );
  }
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF6A8C6);
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.92)
      ..cubicTo(
        size.width * 1.02,
        size.height * 0.58,
        size.width * 0.98,
        size.height * 0.12,
        size.width * 0.66,
        size.height * 0.14,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.14,
        size.width * 0.5,
        size.height * 0.23,
        size.width * 0.5,
        size.height * 0.26,
      )
      ..cubicTo(
        size.width * 0.5,
        size.height * 0.23,
        size.width * 0.44,
        size.height * 0.14,
        size.width * 0.34,
        size.height * 0.14,
      )
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.12,
        -size.width * 0.02,
        size.height * 0.58,
        size.width * 0.5,
        size.height * 0.92,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafetyTree extends StatelessWidget {
  const _SafetyTree();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 126,
      child: CustomPaint(painter: _TreePainter()),
    );
  }
}

class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trunk = Paint()
      ..color = AppPalette.darkPlum
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.12),
      Offset(size.width * 0.5, size.height * 0.88),
      trunk,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.34),
      Offset(size.width * 0.66, size.height * 0.18),
      trunk,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.44),
      Offset(size.width * 0.32, size.height * 0.28),
      trunk,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.56),
      Offset(size.width * 0.68, size.height * 0.44),
      trunk,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.62),
      Offset(size.width * 0.38, size.height * 0.5),
      trunk,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PersonCluster extends StatelessWidget {
  const _PersonCluster({
    required this.direction,
    this.mirrored = false,
  });

  final Axis direction;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _PersonFigure(
          bodyColor: Color(0xFF3F4160),
          accentColor: Color(0xFFF282A8),
          skinColor: Color(0xFFF2B3B7),
          skirt: true,
        ),
        SizedBox(width: 8),
        _PersonFigure(
          bodyColor: Color(0xFF3B3455),
          accentColor: Color(0xFFF9A0B1),
          skinColor: Color(0xFFF7C2C9),
        ),
      ],
    );

    return mirrored
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
            child: child,
          )
        : child;
  }
}

class _PersonFigure extends StatelessWidget {
  const _PersonFigure({
    required this.bodyColor,
    required this.accentColor,
    required this.skinColor,
    this.skirt = false,
  });

  final Color bodyColor;
  final Color accentColor;
  final Color skinColor;
  final bool skirt;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 96,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: skinColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 6,
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 22,
            child: Container(
              width: 25,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 32,
            child: Container(
              width: skirt ? 30 : 22,
              height: skirt ? 30 : 28,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: 58,
            left: 14,
            child: Container(
              width: 6,
              height: 28,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 58,
            right: 14,
            child: Container(
              width: 6,
              height: 28,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 28,
            left: 6,
            child: Transform.rotate(
              angle: 0.48,
              child: Container(
                width: 6,
                height: 26,
                decoration: BoxDecoration(
                  color: skinColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 6,
            child: Transform.rotate(
              angle: -0.34,
              child: Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: skinColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfinityBadge extends StatelessWidget {
  const _InfinityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: AppPalette.softRose.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.all_inclusive_rounded,
          size: 42,
          color: AppPalette.primaryRose,
        ),
      ),
    );
  }
}
