precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform float uSpeed;
uniform float uSpread;
uniform float uSize;
uniform float uComplexity;
uniform int uBallCount;
uniform vec3 uColor;
varying vec2 vUv;

// New motion function - Phase 1 implementation
vec2 getBallPosition(int id, float time) {
    float harmonicX = 1.0 + float(id % 3) * uComplexity;
    float harmonicY = 1.0 + float((id + 1) % 4) * uComplexity;
    float phase = float(id) * 0.2;
    
    return vec2(
        cos(time * uSpeed * harmonicX + phase) * uSpread,
        sin(time * uSpeed * harmonicY * 1.3 + phase) * uSpread
    );
}

void main() {
    // Normalized coordinates with aspect ratio correction
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    
    // Generate metaballs with new motion
    for (int i = 0; i < 500; i++) { // Increased max to match Leva max
        if (i >= uBallCount) break;
        
        vec2 center = getBallPosition(i, iTime);
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    // Visualize with smooth threshold
    float mask = smoothstep(0.7, 0.72, field);
    gl_FragColor = vec4(uColor * mask, 1.0);
}