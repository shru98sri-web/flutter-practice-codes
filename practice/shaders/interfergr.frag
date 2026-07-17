#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float uWidth;
uniform float uHeight;
uniform float uR;
uniform float uD;
uniform float uLambda;

out vec4 fragColor;

void main() {
    vec2 center = vec2(uWidth / 2.0, uHeight / 2.0);
    float r = distance(FlutterFragCoord().xy, center);

    float maxRadius = min(uWidth, uHeight) / 2.0;
    float normalizedRadius = r / maxRadius;
    float theta = normalizedRadius * 0.05;

    float F = (4.0 * uR) / pow(1.0 - uR, 2.0);
    float delta = (4.0 * 3.14159265 * uD * cos(theta)) / uLambda;
    float intensity = 1.0 / (1.0 + F * pow(sin(delta / 2.0), 2.0));

    // वेव्हलेंथ नुसार डायनॅमिक कलर सिलेक्शन
    vec3 laserColor;
    if (uLambda < 600.0) {
        laserColor = vec3(0.0, 1.0, 0.0); // Green (हिरवा)
    } else {
        laserColor = vec3(1.0, 0.0, 0.0); // Red (लाल)
    }

    fragColor = vec4(laserColor * intensity, 1.0);
}
