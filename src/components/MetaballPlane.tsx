import { useFrame, useThree } from "@react-three/fiber";
import { useRef } from "react";
import * as THREE from "three";
import { useControls } from "leva";
import metaballShader from "../shaders/metaballShader.glsl?raw";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size } = useThree();

    // Leva controls - simplified for motion focus
    const controls = useControls("Metaballs", {
        ballCount: { value: 250, min: 1, max: 500, step: 1 },
        speed: { value: 0.8, min: 0, max: 2, step: 0.1 },
        spread: { value: 0.95, min: 0.1, max: 1.5, step: 0.05 },
        size: { value: 0.01, min: 0.01, max: 0.5, step: 0.01 },
        complexity: { value: 1.5, min: 0.5, max: 3, step: 0.1 }, // New control
    });

    useFrame(({ clock }) => {
        if (materialRef.current) {
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();
            materialRef.current.uniforms.iResolution.value.set(
                size.width,
                size.height
            );
            // Only update motion-related uniforms each frame
            materialRef.current.uniforms.uSpeed.value = controls.speed;
            materialRef.current.uniforms.uSpread.value = controls.spread;
            materialRef.current.uniforms.uComplexity.value =
                controls.complexity;
        }
    });

    return (
        <mesh>
            <planeGeometry args={[2, 2]} />
            <shaderMaterial
                ref={materialRef}
                key={`mb-${controls.ballCount}-${controls.size}`} // Only rebuild when these change
                uniforms={{
                    iTime: { value: 0 },
                    iResolution: {
                        value: new THREE.Vector2(size.width, size.height),
                    },
                    uSpeed: { value: controls.speed },
                    uSpread: { value: controls.spread },
                    uSize: { value: controls.size },
                    uComplexity: { value: controls.complexity },
                    uBallCount: { value: controls.ballCount },
                    uColor: { value: new THREE.Color("#ffffff") },
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
