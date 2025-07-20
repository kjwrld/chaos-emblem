precision highp float;

#define TWO_PI 6.28318530718
#define PI 3.14159265359

uniform vec2 iResolution;
uniform float iTime;
uniform float uSpeed;
uniform float uSpread;
uniform float uSize;
uniform int uBallCount;
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

// Star uniforms
uniform float uStarScale;
uniform float uStarInnerRadius;
uniform float uStarOuterRadius;
uniform float uStarRotation;

varying vec2 vUv;

float getMorphState(float time) {
    // 3-state cycle: Lemniscate -> Star -> Circle -> back to Lemniscate
    float cycle = (uHoldDuration * 3.0) + (uTransitionDuration * 3.0); // Full cycle with all transitions
    float phase = mod(time * uMorphSpeed, cycle);
    
    float state1End = uHoldDuration;
    float transition1End = state1End + uTransitionDuration;
    float state2End = transition1End + uHoldDuration;
    float transition2End = state2End + uTransitionDuration;
    float state3End = transition2End + uHoldDuration;
    float transition3End = state3End + uTransitionDuration; // Circle back to Lemniscate
    
    if (phase < state1End) {
        return 0.0; // Hold lemniscate
    } else if (phase < transition1End) {
        // Transition lemniscate -> star (0.0 -> 1.0)
        return smoothstep(0.0, 1.0, (phase - state1End) / uTransitionDuration);
    } else if (phase < state2End) {
        return 1.0; // Hold star
    } else if (phase < transition2End) {
        // Transition star -> circle (1.0 -> 2.0)
        return 1.0 + smoothstep(0.0, 1.0, (phase - state2End) / uTransitionDuration);
    } else if (phase < state3End) {
        return 2.0; // Hold circle
    } else {
        // Transition circle -> lemniscate (2.0 -> 3.0, then wrap back to 0.0)
        return 2.0 + smoothstep(0.0, 1.0, (phase - state3End) / uTransitionDuration);
    }
}

// Function to apply asymmetric distortion based on vertical position
vec2 applyLogoDistortion(vec2 point) {
    float y = point.y;
    float normalizedY = (y + 1.0) * 0.5;
    
    float topInfluence = smoothstep(0.3, 0.8, normalizedY);
    float bottomInfluence = smoothstep(0.8, 0.3, normalizedY);
    
    float widthMultiplier = mix(
        uBottomWidthMultiplier,
        uTopWidthMultiplier,
        topInfluence
    );
    
    point.x *= mix(1.0, widthMultiplier, uAsymmetryStrength);
    float centerInfluence = 1.0 - abs(y);
    point.y += uCenterOffset * centerInfluence * uAsymmetryStrength;
    
    return point;
}

// Enhanced lemniscate with logo-matching distortion
vec2 getLemniscatePosition(float t, float time) {
    vec2 curvePoint = vec2(
        sin(t),
        sin(t) * cos(t)
    );
    
    float angle = t;
    float distortion = 1.0 + uOverallDistortion * sin((angle + time) * uDistortionFreq);
    float v_distortion = 1.0 + uOverallDistortion * -cos((angle + time) * uDistortionFreq) * uVDistortionMultiplier;
    
    curvePoint.x *= distortion;
    curvePoint.y *= distortion * v_distortion;
    
    curvePoint *= uLemniscateScale;
    curvePoint *= uLemniscateAxisScale;
    curvePoint = applyLogoDistortion(curvePoint);
    
    return curvePoint;
}

// Get 8-pointed star vertex position
vec2 getStarVertex(int vertexIndex) {
    float angle = float(vertexIndex) * PI / 4.0 + uStarRotation;
    float radius = (vertexIndex % 2 == 0) ? uStarOuterRadius : uStarInnerRadius;
    return vec2(cos(angle), sin(angle)) * radius * uStarScale;
}

// Get star position using skip-2 pattern (A->D->G->B->E->H->C->F->A)
vec2 getStarPosition(float t, float time) {
    float ballProgress = t + time * uSpeed * 0.3;
    
    int skipPattern[8] = int[8](0, 3, 6, 1, 4, 7, 2, 5);
    
    float segmentFloat = mod(ballProgress * 8.0 / TWO_PI, 8.0);
    int currentSegment = int(floor(segmentFloat));
    float segmentProgress = fract(segmentFloat);
    
    int fromVertex = skipPattern[currentSegment % 8];
    int toVertex = skipPattern[(currentSegment + 1) % 8];
    
    vec2 fromPos = getStarVertex(fromVertex);
    vec2 toPos = getStarVertex(toVertex);
    
    float smoothProgress = smoothstep(0.0, 1.0, segmentProgress);
    return mix(fromPos, toPos, smoothProgress);
}

void main() {
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    float morphState = getMorphState(iTime);
    
    for (int i = 0; i < 500; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        
        // Pattern 1: Logo-distorted Lemniscate
        float lemniscateParam = angle + iTime * uSpeed * 0.3;
        vec2 pattern1 = getLemniscatePosition(lemniscateParam, iTime);
        
        // Pattern 2: 8-pointed star with skip-2 pattern
        vec2 pattern2 = getStarPosition(angle, iTime);
        
        // Pattern 3: Original circular motion
        vec2 pattern3 = vec2(
            cos(angle + iTime * uSpeed) * uSpread,
            sin(angle + iTime * uSpeed) * uSpread
        );
        
        // Blend between patterns based on morphState
        vec2 center;
        if (morphState < 1.0) {
            // Lemniscate to Star (0.0 -> 1.0)
            center = mix(pattern1, pattern2, morphState);
        } else if (morphState < 2.0) {
            // Star to Circle (1.0 -> 2.0)
            center = mix(pattern2, pattern3, morphState - 1.0);
        } else if (morphState < 3.0) {
            // Circle back to Lemniscate (2.0 -> 3.0)
            center = mix(pattern3, pattern1, morphState - 2.0);
        } else {
            // Fallback (shouldn't happen with proper modulo)
            center = pattern1;
        }
        
        float dist = length(uv - center);
        field += sizeSquared / (dist * dist);
    }
    
    float mask = smoothstep(0.5, 0.55, field);
    gl_FragColor = vec4(vec3(mask), 1.0);
}