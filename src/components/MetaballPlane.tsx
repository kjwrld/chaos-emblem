import { useFrame, useThree } from "@react-three/fiber";
import { useRef, useEffect } from "react";
import * as THREE from "three";
import { useControls } from "leva";
import metaballShader from "../shaders/metaballShader.glsl?raw";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size } = useThree();

    // Leva controls with ball count
    const controls = useControls("Metaballs", {
        ballCount: { value: 2, min: 1, max: 6, step: 1 },
        speed: { value: 0.5, min: 0, max: 2, step: 0.1 },
        size: { value: 0.2, min: 0.1, max: 0.5, step: 0.01 },
        spacing: { value: 0.3, min: 0.1, max: 1, step: 0.05 },
        threshold: { value: 0.7, min: 0.1, max: 1, step: 0.01 },
        smoothness: { value: 0.02, min: 0.001, max: 0.1, step: 0.001 },
        color: { value: "#ffffff" },
    });

    // Create a key that changes when controls affecting the shader change
    const shaderKey = `${controls.ballCount}-${controls.size}-${controls.spacing}`;

    useFrame(({ clock }) => {
        if (materialRef.current) {
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();
            materialRef.current.uniforms.iResolution.value.set(
                size.width,
                size.height
            );
            materialRef.current.uniforms.uSpeed.value = controls.speed;
            materialRef.current.uniforms.uSize.value = controls.size;
            materialRef.current.uniforms.uSpacing.value = controls.spacing;
            materialRef.current.uniforms.uThreshold.value = controls.threshold;
            materialRef.current.uniforms.uSmoothness.value =
                controls.smoothness;
            materialRef.current.uniforms.uColor.value = new THREE.Color(
                controls.color
            );
            materialRef.current.uniforms.uBallCount.value = controls.ballCount;
        }
    });

    return (
        <mesh>
            <planeGeometry args={[2, 2]} />
            <shaderMaterial
                key={shaderKey} // Force re-creation when key changes
                ref={materialRef}
                uniforms={{
                    iTime: { value: 0 },
                    iResolution: {
                        value: new THREE.Vector2(size.width, size.height),
                    },
                    uSpeed: { value: controls.speed },
                    uSize: { value: controls.size },
                    uSpacing: { value: controls.spacing },
                    uThreshold: { value: controls.threshold },
                    uSmoothness: { value: controls.smoothness },
                    uColor: { value: new THREE.Color(controls.color) },
                    uBallCount: { value: controls.ballCount },
                }}
                fragmentShader={metaballShader}
                vertexShader={`
                    varying vec2 vUv;
                    void main() {
                        vUv = position.xy * 0.5 + 0.5;
                        gl_Position = vec4(position, 1.0);
                    }
                `}
            />
        </mesh>
    );
}
