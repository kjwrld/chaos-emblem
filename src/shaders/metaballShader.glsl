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
uniform float uHoldDuration;
uniform float uTransitionDuration;

// Lemniscate distortion uniforms
uniform float uOverallDistortion;
uniform float uVDistortionMultiplier;
uniform float uDistortionFreq;
uniform float uLemniscateScale;
uniform vec2 uLemniscateAxisScale;

// New asymmetric distortion uniforms for logo matching
uniform float uTopWidthMultiplier;    // How much wider the top should be
uniform float uBottomWidthMultiplier; // How much narrower the bottom should be  
uniform float uCenterOffset;          // Vertical offset for the center point
uniform float uAsymmetryStrength;     // Overall strength of the asymmetric effect

varying vec2 vUv;

float getMorphState(float time) {
    float cycle = uHoldDuration * 2.0 + uTransitionDuration * 2.0;
    float phase = mod(time, cycle);
    
    if (phase < uHoldDuration) {
        return 0.0;
    } else if (phase < uHoldDuration + uTransitionDuration) {
        return smoothstep(0.0, 1.0, (phase - uHoldDuration) / uTransitionDuration);
    } else if (phase < uHoldDuration * 2.0 + uTransitionDuration) {
        return 1.0;
    } else {
        return 1.0 - smoothstep(0.0, 1.0, (phase - (uHoldDuration * 2.0 + uTransitionDuration)) / uTransitionDuration);
    }
}

// Function to apply asymmetric distortion based on vertical position
vec2 applyLogoDistortion(vec2 point) {
    float y = point.y;
    
    // Create smooth transitions between top and bottom scaling
    // Map y from [-1, 1] to [0, 1] for easier interpolation
    float normalizedY = (y + 1.0) * 0.5;
    
    // Create asymmetric scaling factors
    // Top gets wider, bottom gets narrower
    float topInfluence = smoothstep(0.3, 0.8, normalizedY);
    float bottomInfluence = smoothstep(0.8, 0.3, normalizedY);
    
    float widthMultiplier = mix(
        uBottomWidthMultiplier,  // Bottom (narrower)
        uTopWidthMultiplier,     // Top (wider)
        topInfluence
    );
    
    // Apply asymmetric scaling
    point.x *= mix(1.0, widthMultiplier, uAsymmetryStrength);
    
    // Apply center offset - stronger effect in the middle
    float centerInfluence = 1.0 - abs(y); // Stronger at center (y=0)
    point.y += uCenterOffset * centerInfluence * uAsymmetryStrength;
    
    return point;
}

// Enhanced lemniscate with logo-matching distortion
vec2 getLemniscatePosition(float t, float time) {
    // Base lemniscate curve
    vec2 curvePoint = vec2(
        sin(t),
        sin(t) * cos(t)
    );
    
    // Apply your existing InfinityTube distortion
    float angle = t;
    float distortion = 1.0 + uOverallDistortion * sin((angle + time) * uDistortionFreq);
    float v_distortion = 1.0 + uOverallDistortion * -cos((angle + time) * uDistortionFreq) * uVDistortionMultiplier;
    
    curvePoint.x *= distortion;
    curvePoint.y *= distortion * v_distortion;
    
    // Apply scaling
    curvePoint *= uLemniscateScale;
    curvePoint *= uLemniscateAxisScale;
    
    // Apply the new asymmetric logo distortion
    curvePoint = applyLogoDistortion(curvePoint);
    
    return curvePoint;
}

void main() {
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    float blend = getMorphState(iTime);
    
    for (int i = 0; i < 500; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        
        // Pattern 1: Original circular motion
        vec2 pattern1 = vec2(
            -cos(angle + iTime * uSpeed) * uSpread,
            sin(angle + iTime * uSpeed) * uSpread
        );
        
        // Pattern 2: Logo-distorted Lemniscate
        float lemniscateParam = angle + iTime * uSpeed * 0.3;
        vec2 pattern2 = getLemniscatePosition(lemniscateParam, iTime);
        
        // Blend between patterns
        vec2 center = mix(pattern1, pattern2, blend);
        
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    float mask = smoothstep(0.5, 0.55, field);
    gl_FragColor = vec4(uColor * mask, 1.0);
}