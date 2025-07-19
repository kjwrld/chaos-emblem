import { useFrame, useThree } from "@react-three/fiber";
import { useRef, useEffect, useState, useMemo } from "react";
import * as THREE from "three";
import { useControls } from "leva";
import metaballShader from "../shaders/metaballShader.glsl?raw";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size, viewport } = useThree();
    const [resolution, setResolution] = useState(() => new THREE.Vector2());
    const resizeTimeout = useRef<NodeJS.Timeout | null>(null);

    // Leva controls with your parameters
    const controls = useControls("Metaballs", {
        ballCount: { value: 150, min: 1, max: 500, step: 1 },
        speed: { value: 0.4, min: 0, max: 2, step: 0.1 },
        spread: { value: 0.5, min: 0.1, max: 1.5, step: 0.05 },
        size: { value: 0.01, min: 0.01, max: 0.5, step: 0.01 },
        complexity: { value: 3.0, min: 0.5, max: 3, step: 0.1 },
    });

    // Debounced resize handler
    useEffect(() => {
        const handleResize = () => {
            if (resizeTimeout.current) clearTimeout(resizeTimeout.current);
            resizeTimeout.current = setTimeout(() => {
                setResolution(new THREE.Vector2(size.width, size.height));
            }, 100);
        };

        handleResize(); // Initial set
        window.addEventListener("resize", handleResize);
        return () => {
            window.removeEventListener("resize", handleResize);
            if (resizeTimeout.current) clearTimeout(resizeTimeout.current);
        };
    }, [size]);

    // Memoize uniforms that don't change often
    const staticUniforms = useMemo(
        () => ({
            uSize: { value: controls.size },
            uBallCount: { value: controls.ballCount },
            uColor: { value: new THREE.Color("#ffffff") },
        }),
        [controls.size, controls.ballCount]
    );

    useFrame(({ clock }) => {
        if (materialRef.current) {
            // Only update time-sensitive uniforms
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();
            materialRef.current.uniforms.uSpeed.value = controls.speed;
            materialRef.current.uniforms.uSpread.value = controls.spread;
            materialRef.current.uniforms.uComplexity.value =
                controls.complexity;

            // Only update resolution if changed
            if (
                !materialRef.current.uniforms.iResolution.value.equals(
                    resolution
                )
            ) {
                materialRef.current.uniforms.iResolution.value.copy(resolution);
            }
        }
    });

    return (
        <mesh>
            <planeGeometry args={[viewport.width, viewport.height]} />
            <shaderMaterial
                ref={materialRef}
                key={`mb-${controls.ballCount}-${
                    controls.size
                }-${resolution.x.toFixed(0)}x${resolution.y.toFixed(0)}`}
                uniforms={{
                    ...staticUniforms,
                    iTime: { value: 0 },
                    iResolution: { value: resolution },
                    uSpeed: { value: controls.speed },
                    uSpread: { value: controls.spread },
                    uComplexity: { value: controls.complexity },
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
