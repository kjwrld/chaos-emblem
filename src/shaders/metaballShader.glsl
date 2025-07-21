precision highp float;

#define TWO_PI 6.28318530718
#define PI 3.14159265359
#define EPSILON 0.001
#define MAX_FIELD 3.0
#define GRADIENT_EPSILON 0.01

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

// Asymmetric distortion uniforms
uniform float uTopWidthMultiplier;
uniform float uBottomWidthMultiplier; 
uniform float uCenterOffset;
uniform float uAsymmetryStrength;

// Star uniforms
uniform float uStarScale;
uniform float uStarInnerRadius;
uniform float uStarOuterRadius;
uniform float uStarRotation;

// New effect uniforms
uniform float uBloomIntensity;
uniform float uBloomRadius;
uniform float uChromaticAberration;
uniform float uLuminanceBoost;
uniform float uReflectionStrength;
uniform float uFresnelPower;
uniform float uRoughness;
uniform float uMetallic;
uniform vec3 uLightDirection;
uniform vec3 uLightColor;
uniform float uAmbientStrength;

uniform samplerCube uEnvMap;
uniform sampler2D uNoiseTexture;

varying vec2 vUv;

// PCG Hash for stochastic variety
uint pcg(uint v) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

float random(float seed) {
    return float(pcg(uint(seed * 4096.0))) / 4294967296.0;
}

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

// Calculate metaball field with stochastic variety
float calculateMetaballField(vec2 uv, float morphState) {
    float field = 0.0;
    float sizeSquared = uSize * uSize;
    
    for (int i = 0; i < 250; i++) {
        if (i >= uBallCount) break;
        
        float angle = float(i) * (TWO_PI / float(uBallCount));
        
        // Add stochastic variety to each ball
        float randomOffset = random(float(i)) * 0.1;
        float timeOffset = iTime + randomOffset * 10.0;
        float sizeVariation = 0.8 + 0.4 * random(float(i) + 100.0);
        
        // Pattern calculations with variety
        float lemniscateParam = angle + timeOffset * uSpeed * 0.3;
        vec2 pattern1 = getLemniscatePosition(lemniscateParam, timeOffset);
        vec2 pattern2 = getLemniscatePosition(lemniscateParam, timeOffset);
        vec2 pattern3 = getStarPosition(angle, timeOffset);
        
        // Blend between patterns
        vec2 center;
        if (morphState < 1.0) {
            center = mix(pattern1, pattern2, morphState);
        } else if (morphState < 2.0) {
            center = mix(pattern2, pattern3, morphState - 1.0);
        } else if (morphState < 3.0) {
            center = mix(pattern3, pattern1, morphState - 2.0);
        } else {
            center = pattern1;
        }
        
        float dist = length(uv - center);
        float contribution = sizeSquared * sizeVariation / (dist * dist + EPSILON);
        field += contribution;
        
        // Early exit optimization
        if (field > MAX_FIELD) break;
    }
    
    return field;
}

// Calculate physically-plausible normals from field gradients
vec3 calculateNormal(vec2 uv, float morphState) {
    float fieldCenter = calculateMetaballField(uv, morphState);
    float fieldRight = calculateMetaballField(uv + vec2(GRADIENT_EPSILON, 0.0), morphState);
    float fieldUp = calculateMetaballField(uv + vec2(0.0, GRADIENT_EPSILON), morphState);
    
    vec2 gradient = vec2(
        fieldRight - fieldCenter,
        fieldUp - fieldCenter
    ) / GRADIENT_EPSILON;
    
    // Convert 2D gradient to 3D normal
    vec3 normal = normalize(vec3(-gradient.x, -gradient.y, 1.0));
    return normal;
}

// Calculate luminance for bloom effects
float calcLuminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

// Fresnel reflection calculation
float fresnel(vec3 viewDir, vec3 normal, float power) {
    return pow(1.0 - max(0.0, dot(viewDir, normal)), power);
}

// PBR-style reflection with roughness
vec3 sampleEnvironment(vec3 reflectDir, float roughness) {
    // Simple roughness simulation by blurring reflection direction
    vec3 perturbedDir = reflectDir + (texture2D(uNoiseTexture, gl_FragCoord.xy / 512.0).xyz - 0.5) * roughness;
    return textureCube(uEnvMap, normalize(perturbedDir)).rgb;
}

// Chromatic aberration effect
vec3 chromaticAberration(vec2 uv, float field, float strength) {
    vec2 offset = normalize(uv) * strength * smoothstep(0.3, 1.0, field);
    
    float r = calculateMetaballField(uv + offset * 0.01, getMorphState(iTime));
    float g = calculateMetaballField(uv, getMorphState(iTime));
    float b = calculateMetaballField(uv - offset * 0.01, getMorphState(iTime));
    
    return vec3(r, g, b);
}

void main() {
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 2.0;
    float morphState = getMorphState(iTime);
    
    // Calculate field with chromatic aberration
    vec3 fieldRGB = chromaticAberration(uv, 0.0, uChromaticAberration);
    float field = (fieldRGB.r + fieldRGB.g + fieldRGB.b) / 3.0;
    
    // Calculate mask with temporal bloom
    float baseMask = smoothstep(0.5, 0.55, field);
    float bloomMask = smoothstep(0.3, 0.6, field);
    
    // Calculate physically-plausible normal
    vec3 normal = calculateNormal(uv, morphState);
    
    // Lighting calculations
    vec3 viewDir = normalize(vec3(uv, 1.0));
    vec3 lightDir = normalize(uLightDirection);
    
    // Diffuse lighting
    float NdotL = max(0.0, dot(normal, lightDir));
    vec3 diffuse = uLightColor * NdotL;
    
    // Specular reflection with PBR
    vec3 reflectDir = reflect(-viewDir, normal);
    vec3 envReflection = sampleEnvironment(reflectDir, uRoughness);
    
    // Fresnel effect
    float fresnelFactor = fresnel(viewDir, normal, uFresnelPower);
    
    // Mix metallic and dielectric response
    vec3 specular = mix(envReflection * 0.04, envReflection, uMetallic) * fresnelFactor;
    
    // Combine lighting
    vec3 litColor = (diffuse + specular) * uReflectionStrength;
    vec3 ambient = envReflection * uAmbientStrength;
    
    // Enhanced luminance control
    float litLuminance = calcLuminance(litColor);
    litColor *= uLuminanceBoost * (1.0 + litLuminance);
    
    // Temporal bloom effect
    float bloomIntensity = uBloomIntensity * smoothstep(0.0, 1.0, litLuminance);
    vec3 bloom = litColor * bloomIntensity * bloomMask;
    
    // Background and final composition
    vec3 whiteBg = vec3(1.0);
    vec3 metaballColor = litColor + ambient + bloom;
    
    // Final color mixing
    vec3 finalColor = mix(whiteBg, metaballColor, baseMask);
    
    // Add edge glow for extra visual appeal
    float edge = smoothstep(0.45, 0.5, field) * 0.3;
    finalColor = mix(finalColor, metaballColor * 1.5, edge);
    
    // Tone mapping and gamma correction
    finalColor = finalColor / (finalColor + vec3(1.0));
    finalColor = pow(finalColor, vec3(1.0/2.2));
    
    gl_FragColor = vec4(finalColor, 1.0);
}