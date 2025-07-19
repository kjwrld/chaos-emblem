precision highp float;

uniform vec2 iResolution;
uniform float iTime;
varying vec2 vUv;

void main() {
    // Use normalized coordinates [0,1] with proper aspect ratio
    vec2 uv = (vUv - 0.5) * vec2(iResolution.x/iResolution.y, 1.0) * 4.0;
    
    // Dynamic metaball count with simpler distance calculation
    float dist1 = length(uv - vec2(sin(iTime * 0.5), cos(iTime * 0.5)) * 0.3);
    float dist2 = length(uv - vec2(sin(iTime * 0.8 + 1.0), cos(iTime * 0.8 + 1.0)) * 0.3);
    
    // Optimized metaball calculation
    float field = 0.04/(dist1*dist1) + 0.04/(dist2*dist2);
    float mask = smoothstep(0.7, 0.72, field);
    
    gl_FragColor = vec4(vec3(mask), 1.0);
}