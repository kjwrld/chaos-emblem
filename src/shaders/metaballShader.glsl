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

#define MAX_BALLS 500
#define EARLY_EXIT 1 // Optimization flag

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
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0);
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    float threshold = 0.7;
    
    // Optimized loop with early exit
    for (int i = 0; i < MAX_BALLS; i++) {
        #if EARLY_EXIT
        if (i >= uBallCount) break;
        #endif
        
        vec2 center = getBallPosition(i, iTime);
        vec2 delta = uv - center;
        float invDistSq = sizeSquared / dot(delta, delta);
        
        // Early exit if contribution becomes negligible
        if (invDistSq < 0.001) continue;
        
        field += invDistSq;
        
        // Early threshold check
        if (field > 50.0) break; // Empirical value for 500 balls
    }
    
    float mask = smoothstep(threshold, threshold + 0.02, field);
    gl_FragColor = vec4(uColor * mask, 1.0);
}