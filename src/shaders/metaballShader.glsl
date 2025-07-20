precision highp float;

#define TWO_PI 6.28318530718

uniform vec2 iResolution;
uniform float iTime;
uniform float uSpeed;
uniform float uSpread;
uniform float uSize;
uniform int uBallCount;
uniform vec3 uColor;
uniform float uMorphSpeed;
uniform float uHoldDuration; // Seconds to hold at each pattern
uniform float uTransitionDuration; // Seconds for morph transition
varying vec2 vUv;

float getMorphState(float time) {
    float cycle = uHoldDuration * 2.0 + uTransitionDuration * 2.0;
    float phase = mod(time, cycle);
    
    if (phase < uHoldDuration) {
        return 0.0; // Hold first pattern
    } else if (phase < uHoldDuration + uTransitionDuration) {
        // Smooth transition to second pattern
        return smoothstep(0.0, 1.0, (phase - uHoldDuration) / uTransitionDuration);
    } else if (phase < uHoldDuration * 2.0 + uTransitionDuration) {
        return 1.0; // Hold second pattern
    } else {
        // Smooth transition back to first pattern
        return 1.0 - smoothstep(0.0, 1.0, (phase - (uHoldDuration * 2.0 + uTransitionDuration)) / uTransitionDuration);
    }
}

// Lemniscate (infinity symbol) parametric function
vec2 getLemniscatePosition(float t, float scale) {
    float cosT = cos(t);
    float sinT = sin(t);
    float denom = 1.0 + sinT * sinT;
    
    return vec2(
        scale * cosT / denom,
        scale * sinT * cosT / denom
    );
}

void main() {
    // Normalized coordinates with aspect ratio correction
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    float blend = getMorphState(iTime);
    
    // Enhanced motion with lemniscate pattern
    for (int i = 0; i < 500; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        
        // Pattern 1: Original circular motion
        vec2 pattern1 = vec2(
            cos(angle + iTime * uSpeed) * uSpread,
            sin(angle + iTime * uSpeed) * uSpread
        );
        
        // Pattern 2: Lemniscate (infinity symbol) with flowing motion
        float lemniscateParam = angle + iTime * uSpeed * 0.3;
        vec2 pattern2 = getLemniscatePosition(lemniscateParam, uSpread * 1.2);
        
        // Add some breathing motion to the lemniscate
        // float breathe = 0.1 * sin(iTime * 2.0);
        // pattern2 *= (1.0 + breathe);
        
        // Blend between patterns
        vec2 center = mix(pattern1, pattern2, blend);
        
        // Optimized distance calculation
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    // Visualize with threshold
    float mask = smoothstep(0.5, 0.55, field);
    gl_FragColor = vec4(uColor * mask, 1.0);
}