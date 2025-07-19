precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform float uSpeed;
uniform float uSpread;
uniform float uSize;
uniform int uBallCount;
uniform vec3 uColor;
uniform float uMorphSpeed;
varying vec2 vUv;

void main() {
    // Normalized coordinates with aspect ratio correction
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    
    // Basic motion with morphing effect
    for (int i = 0; i < 500; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (6.283185 / float(uBallCount));
        
        // Two different motion patterns to blend between
        vec2 pattern1 = vec2(
            cos(angle + iTime * uSpeed) * uSpread,
            sin(angle + iTime * uSpeed) * uSpread
        );
        
        vec2 pattern2 = vec2(
            cos(angle * 2.0 + iTime * uSpeed * 0.5) * uSpread * 0.8,
            sin(angle * 3.0 + iTime * uSpeed * 0.7) * uSpread * 0.8
        );
        
        // Blend between patterns based on time
        float blend = sin(iTime * uMorphSpeed) * 0.5 + 0.5;
        vec2 center = mix(pattern1, pattern2, blend);
        
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    // Visualize with threshold
    float mask = smoothstep(0.5, 0.55, field);
    gl_FragColor = vec4(uColor * mask, 1.0);
}