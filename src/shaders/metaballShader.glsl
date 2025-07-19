precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform float uSpeed;
uniform float uSize;
uniform float uSpacing;
uniform float uThreshold;
uniform float uSmoothness;
uniform vec3 uColor;
uniform int uBallCount;
varying vec2 vUv;

void main() {
    // Normalized coordinates with aspect ratio correction
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    
    // Generate metaballs based on count
    for (int i = 0; i < 6; i++) {
        if (i >= uBallCount) break;
        
        // Calculate unique position for each ball
        float angle = float(i) * (6.283185 / float(uBallCount));
        float timeOffset = float(i) * 0.5;
        vec2 center = vec2(
            sin(iTime * uSpeed + timeOffset) * uSpacing,
            cos(iTime * uSpeed + timeOffset) * uSpacing
        );
        
        // Rotate positions around circle
        center = vec2(
            center.x * cos(angle) - center.y * sin(angle),
            center.x * sin(angle) + center.y * cos(angle)
        );
        
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    // Smooth threshold with controls
    float mask = smoothstep(uThreshold, uThreshold + uSmoothness, field);
    
    // Apply color
    gl_FragColor = vec4(uColor * mask, 1.0);
}