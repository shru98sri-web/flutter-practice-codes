import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GameWidget(game: CarSimulationGame()));
}

class CarSimulationGame extends FlameGame with KeyboardEvents {
  late Car car;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // स्क्रीनच्या मध्यभागी कारची पोझिशन सेट करणे
    car = Car(startPosition: size / 2);
    await add(car);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    car.updateControls(keysPressed);
    return KeyEventResult.handled;
  }
}

class Car extends PositionComponent with HasGameRef<CarSimulationGame> {
  // भौतिकशास्त्र स्थिर मूल्ये (Physics Constants)
  double speed = 0.0;
  final double maxSpeed = 300.0;
  final double maxReverseSpeed = -100.0;
  final double acceleration = 150.0;
  final double braking = 300.0;
  final double friction = 0.98;
  final double turnSpeed = 2.5;

  // नियंत्रणे (Control Flags)
  bool isAccelerating = false;
  bool isBraking = false;
  bool isTurningLeft = false;
  bool isTurningRight = false;

  Car({required Vector2 startPosition}) {
    position = startPosition;
    size = Vector2(40, 20); // कारचा आकार (लांबी, रुंदी)
    anchor = Anchor.center; // रोटेशन मध्यभागातून होण्यासाठी
  }

  void updateControls(Set<LogicalKeyboardKey> keys) {
    isAccelerating = keys.contains(LogicalKeyboardKey.keyW) || keys.contains(LogicalKeyboardKey.arrowUp);
    isBraking = keys.contains(LogicalKeyboardKey.keyS) || keys.contains(LogicalKeyboardKey.arrowDown);
    isTurningLeft = keys.contains(LogicalKeyboardKey.keyA) || keys.contains(LogicalKeyboardKey.arrowLeft);
    isTurningRight = keys.contains(LogicalKeyboardKey.keyD) || keys.contains(LogicalKeyboardKey.arrowRight);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // १. वेग वाढवणे आणि ब्रेक दाबणे (Acceleration & Braking)
    if (isAccelerating) {
      speed += acceleration * dt;
    } else if (isBraking) {
      speed -= braking * dt;
    } else {
      speed *= friction; // कोणताही की-प्रेस नसताना वेग हळूहळू कमी होणे
    }

    // वेगाची मर्यादा निश्चित करणे (Speed Clamping)
    speed = speed.clamp(maxReverseSpeed, maxSpeed);

    // २. स्टिअरिंग नियंत्रण (Steering Control)
    // कार जागच्या जागी फिरू नये म्हणून किमान वेग असणे आवश्यक आहे
    if (speed.abs() > 5) {
      // रिव्हर्स जाताना स्टिअरिंग दिशा उलट करणे
      double directionMultiplier = speed > 0 ? 1.0 : -1.0;

      if (isTurningLeft) {
        angle -= turnSpeed * directionMultiplier * dt;
      }
      if (isTurningRight) {
        angle += turnSpeed * directionMultiplier * dt;
      }
    }

    // ३. नवीन पोझिशन कॅल्क्युलेशन (Vector Math)
    position.x += cos(angle) * speed * dt;
    position.y += sin(angle) * speed * dt;

    // ४. स्क्रीनच्या बाहेर गेल्यास दुसऱ्या बाजूने एन्ट्री (Screen Wrapping)
    if (position.x > gameRef.size.x) position.x = 0;
    if (position.x < 0) position.x = gameRef.size.x;
    if (position.y > gameRef.size.y) position.y = 0;
    if (position.y < 0) position.y = gameRef.size.y;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // कारची रचना (Chassis Painting)
    final paintBody = Paint()..color = const Color(0xFF2196F3); // निळी कार
    final paintFront = Paint()..color = const Color(0xFFF44336); // लाल हेडलाईट (दिशा समजण्यासाठी)

    // मुख्य कार बॉडी ड्रा करणे
    canvas.drawRect(Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y), paintBody);

    // कारची पुढची बाजू ओळखण्यासाठी लाल पट्टी ड्रा करणे
    canvas.drawRect(Rect.fromLTWH(size.x / 4, -size.y / 2, size.x / 4, size.y), paintFront);
  }
}
