import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapis_antonello_ghezzi/controller/providers.dart';

final _random = Random();

class ParticleSystem extends ConsumerStatefulWidget {
  const ParticleSystem({Key? key}) : super(key: key);

  @override
  ConsumerState<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends ConsumerState<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late List<Particle> particles;
  late Ticker _ticker;
  Duration lastParticle = Duration.zero;
  Duration lastUpdate = Duration.zero;

  @override
  void initState() {
    this.particles = [];

    this._ticker = this.createTicker((elapsed) {
      setState(() {
        final speed = ref.read(modelProvider).getSpeedPercentage();
        this.particles = this
            .particles
            .map((p) {
              p.update(speed, (elapsed - this.lastUpdate).inMilliseconds);
              final x = p.getX();
              return x > 1 || x < -1 ? null : p;
            })
            .nonNulls
            .toList();
        this.lastUpdate = elapsed;

        if (ref.read(modelProvider).isRunning()) {
          final probability = (elapsed - this.lastParticle).inMilliseconds;
          if (probability * 4 > _random.nextInt(1000)) {
            List.generate(_random.nextInt(8), (i) => i).forEach((_) {
              this.particles.add(Particle()..randomUpdate(speed));
            });

            this.lastParticle = elapsed;
          }
        } else {
          this.lastParticle = elapsed;
        }
      });
    });
    this._ticker.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          painter: _ParticlePainter(particles: this.particles),
        ));
  }
}

class _ParticlePainter extends CustomPainter {
  List<Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (Particle particle in this.particles) {
      canvas.drawCircle(
          Offset(particle.getX() * size.width, particle.getY() * size.height)
              .translate(size.width / 2, size.height / 2),
          particle.radius,
          Paint()
            ..color = Color.fromARGB(particle.getOpacity(), 220, 220, 220));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

const double fadeInMilliseconds = 500;
const double startingRadius = 1;
const double finalRadius = 6;

class Particle {
  double direction = doubleInRange(0, 2 * pi);
  double distance = 0;
  double radius = startingRadius;
  double opacity = 0;

  Particle();

  void randomUpdate(double speed) {
    this.update(speed, intInRange(100, 1000));
  }

  void update(double speed, int milliseconds) {
    if (speed == 0) {
      return;
    }

    this.distance += speed * milliseconds / 100;

    final double opacityStep = 255 / (fadeInMilliseconds * speed);
    this.opacity += opacityStep * speed * milliseconds;
    if (this.opacity > 255) {
      this.opacity = 255;
    }

    this.radius +=
        (milliseconds * speed * (finalRadius - startingRadius)) / 100;
    if (this.radius > finalRadius) {
      this.radius = finalRadius;
    }
  }

  double getX() {
    final vectorX = cos(this.direction);
    final res = this.distance * vectorX;
    return res;
  }

  double getY() {
    final vectorY = sin(this.direction);
    return this.distance * vectorY;
  }

  int getOpacity() {
    return this.opacity.floor();
  }
}

double doubleInRange(num start, num end) {
  return _random.nextDouble() * (end - start) + start;
}

int intInRange(int start, int end) {
  return _random.nextInt(end - start) + start;
}
