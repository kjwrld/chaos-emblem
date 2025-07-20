import { useFrame, useThree } from "@react-three/fiber";
import { useRef, useEffect, useState } from "react";
import * as THREE from "three";
import { useControls } from "leva";
import metaballShader from "../shaders/metaballShader.glsl?raw";
import Stats from "stats.js";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size, viewport } = useThree();
    const [resolution, setResolution] = useState(new THREE.Vector2());
    const resizeTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);
    const statsRef = useRef<Stats | null>(null);

    // Initialize stats.js
    useEffect(() => {
        const stats = new Stats();
        stats.showPanel(0); // 0: fps, 1: ms, 2: mb, 3+: custom
        document.body.appendChild(stats.dom);
        statsRef.current = stats;

        return () => {
            document.body.removeChild(stats.dom);
        };
    }, []);

    // Simple controls
    const controls = useControls("Metaballs", {
        ballCount: { value: 250, min: 1, max: 500, step: 1 },
        speed: { value: 0.5, min: 0, max: 2, step: 0.1 }, // Controls how fast the individual metaballs move in their patterns
        spread: { value: 0.5, min: 0.1, max: 1.5, step: 0.05 },
        size: { value: 0.01, min: 0.01, max: 0.5, step: 0.01 },
        morphSpeed: { value: 7.5, min: 0.01, max: 10.0, step: 0.01 },
        holdDuration: { value: 10.0, min: 0.1, max: 10.0, step: 0.1 },
        transitionDuration: { value: 7.5, min: 0.1, max: 10.0, step: 0.1 },
    });

    // Handle resize
    useEffect(() => {
        const handleResize = () => {
            if (resizeTimeout.current) {
                clearTimeout(resizeTimeout.current);
            }
            resizeTimeout.current = setTimeout(() => {
                setResolution(new THREE.Vector2(size.width, size.height));
            }, 100);
        };
        window.addEventListener("resize", handleResize);
        return () => {
            window.removeEventListener("resize", handleResize);
            if (resizeTimeout.current) {
                clearTimeout(resizeTimeout.current);
            }
        };
    }, [size]);

    useFrame(({ clock }) => {
        statsRef.current?.begin();

        if (materialRef.current) {
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();
            materialRef.current.uniforms.iResolution.value.set(
                size.width,
                size.height
            );
            materialRef.current.uniforms.uSpeed.value = controls.speed;
            materialRef.current.uniforms.uSpread.value = controls.spread;
            materialRef.current.uniforms.uSize.value = controls.size;
            materialRef.current.uniforms.uBallCount.value = controls.ballCount;
            materialRef.current.uniforms.uMorphSpeed.value =
                controls.morphSpeed;
            materialRef.current.uniforms.uHoldDuration.value =
                controls.holdDuration;
            materialRef.current.uniforms.uTransitionDuration.value =
                controls.transitionDuration;

            if (
                !materialRef.current.uniforms.iResolution.value.equals(
                    resolution
                )
            ) {
                materialRef.current.uniforms.iResolution.value.copy(resolution);
            }
        }

        statsRef.current?.end();
    });

    return (
        <mesh>
            <planeGeometry args={[viewport.width, viewport.height]} />
            <shaderMaterial
                ref={materialRef}
                key={`mb-${controls.ballCount}-${controls.size}-`}
                uniforms={{
                    iTime: { value: 0 },
                    iResolution: { value: resolution },
                    uSpeed: { value: controls.speed },
                    uSpread: { value: controls.spread },
                    uSize: { value: controls.size },
                    uBallCount: { value: controls.ballCount },
                    uColor: { value: new THREE.Color("#ffffff") },
                    uMorphSpeed: { value: controls.morphSpeed },
                    uHoldDuration: { value: controls.holdDuration },
                    uTransitionDuration: { value: controls.transitionDuration },
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
