#version 460 core
#include <flutter/runtime_effect.glsl>

// युनिफॉर्म्सचा क्रम (Dart मधून येणारा डेटा)
uniform float uWidth;
uniform float uHeight;
uniform float uR;
uniform float uD;
uniform float uLambda;
uniform float uFocalLength;

out vec4 fragColor;

void main() {
    // सेंटर कोऑर्डिनेट्स
    vec2 center = vec2(uWidth / 2.0, uHeight / 2.0);

    // सध्याच्या पिक्सेलचे सेंटरपासूनचे अंतर (Radius)
    float r = distance(FlutterFragCoord().xy, center);

    // Angle of incidence (theta)
    float theta = r / uFocalLength;

    // Coefficient of Finesse (F)
    float F = (4.0 * uR) / pow(1.0 - uR, 2.0);

    // Phase difference (delta) - PI = 3.14159265
    float delta = (4.0 * 3.14159265 * uD * cos(theta)) / uLambda;

    // Airy Distribution formula
    float intensity = 1.0 / (1.0 + F * pow(sin(delta / 2.0), 2.0));

    // लेझर कलर - ब्राइट रेड (लाल रंग)
    vec3 laserColor = vec3(1.0, 0.0, 0.0);

    // शेडर आउटपुट पेंट करा
    fragColor = vec4(laserColor * intensity, 1.0);
}
