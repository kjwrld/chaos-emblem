precision highp float;

#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define HALF_PI 1.57079632679

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
uniform float uTopWidthMultiplier;
uniform float uBottomWidthMultiplier; 
uniform float uCenterOffset;
uniform float uAsymmetryStrength;

// Star uniforms
uniform float uStarScale;
uniform float uStarInnerRadius;
uniform float uStarOuterRadius;
uniform float uStarRotation;

// New enhancement uniforms
uniform float uFieldThreshold;
uniform float uNormalStrength;
uniform float uReflectionIntensity;
uniform float uEdgeSmoothing;

uniform samplerCube uEnvMap;

varying vec2 vUv;

// Function definitions in correct order

float getMorphState(float time) {
    float cycle = (uHoldDuration * 3.0) + (uTransitionDuration * 3.0);
    float phase = mod(time * uMorphSpeed, cycle);
    
    float state1End = uHoldDuration;
    float transition1End = state1End + uTransitionDuration;
    float state2End = transition1End + uHoldDuration;
    float transition2End = state2End + uTransitionDuration;
    float state3End = transition2End + uHoldDuration;
    float transition3End = state3End + uTransitionDuration;
    
    if (phase < state1End) {
        return 0.0;
    } else if (phase < transition1End) {
        return smoothstep(0.0, 1.0, (phase - state1End) / uTransitionDuration);
    } else if (phase < state2End) {
        return 1.0;
    } else if (phase < transition2End) {
        return 1.0 + smoothstep(0.0, 1.0, (phase - state2End) / uTransitionDuration);
    } else if (phase < state3End) {
        return 2.0;
    } else {
        return 2.0 + smoothstep(0.0, 1.0, (phase - state3End) / uTransitionDuration);
    }
}

vec2 applyLogoDistortion(vec2 point) {
    float y = point.y;
    float normalizedY = (y + 1.0) * 0.5;
    
    float topInfluence = smoothstep(0.3, 0.8, normalizedY);
    float bottomInfluence = smoothstep(0.8, 0.3, normalizedY);
    
    float widthMultiplier = mix(uBottomWidthMultiplier, uTopWidthMultiplier, topInfluence);
    point.x *= mix(1.0, widthMultiplier, uAsymmetryStrength);
    
    float centerInfluence = 1.0 - abs(y);
    point.y += uCenterOffset * centerInfluence * uAsymmetryStrength;
    
    return point;
}

vec2 getLemniscatePosition(float t, float time) {
    vec2 curvePoint = vec2(sin(t), sin(t) * cos(t));
    
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

vec2 getStarVertex(int vertexIndex) {
    float angle = float(vertexIndex) * PI / 4.0 + uStarRotation;
    float radius = (vertexIndex % 2 == 0) ? uStarOuterRadius : uStarInnerRadius;
    return vec2(cos(angle), sin(angle)) * radius * uStarScale;
}

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

// Helper function to get current pattern position
vec2 getCurrentPatternPosition(float angle, float morphState) {
    float lemniscateParam = angle + iTime * uSpeed * 0.3;
    vec2 pattern1 = getLemniscatePosition(lemniscateParam, iTime);
    vec2 pattern2 = getLemniscatePosition(lemniscateParam, iTime);
    vec2 pattern3 = getStarPosition(angle, iTime);
    
    if (morphState < 1.0) {
        return mix(pattern1, pattern2, morphState);
    } else if (morphState < 2.0) {
        return mix(pattern2, pattern3, morphState - 1.0);
    } else if (morphState < 3.0) {
        return mix(pattern3, pattern1, morphState - 2.0);
    }
    return pattern1;
}

// Enhanced field calculation with gradients for proper normals
void calculateField(vec2 uv, out float field, out vec2 fieldGradient) {
    field = 0.0;
    fieldGradient = vec2(0.0);
    
    float sizeSquared = uSize * uSize;
    float morphState = getMorphState(iTime);
    
    for (int i = 0; i < 250; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        
        // Get position using existing pattern logic
        vec2 center = getCurrentPatternPosition(angle, morphState);
        
        vec2 diff = uv - center;
        float distSq = dot(diff, diff);
        float charge = sizeSquared;
        
        // Prevent division by zero
        distSq = max(distSq, 0.0001);
        
        // Accumulate field
        float contribution = charge / distSq;
        field += contribution;
        
        // Accumulate gradient for normal calculation
        fieldGradient += -2.0 * charge * diff / (distSq * distSq);
        
        if (field > 4.0) break; // Early exit for performance
    }
}

void main() {
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    
    // Calculate original metaball field (your method)
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    float morphState = getMorphState(iTime);
    
    // Also calculate gradients for enhanced normals
    vec2 fieldGradient = vec2(0.0);
    
    for (int i = 0; i < 250; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        vec2 center = getCurrentPatternPosition(angle, morphState);
        
        vec2 diff = uv - center;
        float dist = length(diff);
        float distSq = max(dist * dist, 0.0001);
        
        // Original field calculation
        field += sizeSquared / distSq;
        
        // Gradient calculation for normals
        fieldGradient += -2.0 * sizeSquared * diff / (distSq * distSq);
        
        if (field > 2.0) break;
    }
    
    // Your original masking approach
    float mask = smoothstep(0.5, 0.55, field);
    
    // Calculate enhanced normals from gradients
    float gradientLength = length(fieldGradient);
    vec2 gradientNorm = (gradientLength > 0.001) ? normalize(fieldGradient) : vec2(0.0, 1.0);
    
    // Create 3D surface normal with some curvature
    float curvature = smoothstep(0.4, 0.6, field);
    float normalAngle = curvature * HALF_PI;
    
    vec3 surfaceNormal = normalize(vec3(
        gradientNorm * sin(normalAngle) * uNormalStrength, 
        cos(normalAngle)
    ));
    
    // Sample environment map
    vec3 reflection = textureCube(uEnvMap, surfaceNormal).rgb;
    
    // Your original color scheme: White background with black metaballs showing reflections
    vec3 whiteBg = vec3(1.0);
    vec3 reflectiveMetaballs = reflection * uReflectionIntensity;
    
    // Mix based on mask (same as your original)
    vec3 finalColor = mix(whiteBg, reflectiveMetaballs, mask);
    
    // Optional: Add edge glow (from your original)
    float edge = smoothstep(0.45, 0.5, field) * 0.5;
    finalColor = mix(finalColor, reflection, edge * mask);
    
    gl_FragColor = vec4(finalColor, 1.0);
}