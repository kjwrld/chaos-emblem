import { useFrame, useThree } from "@react-three/fiber";
import { useRef, useEffect, useState } from "react";
import * as THREE from "three";
import metaballShader from "../shaders/metaballShader.glsl?raw";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size, viewport } = useThree();
    const [resolution, setResolution] = useState(() => new THREE.Vector2(0, 0));
    const resizeTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);

    // More efficient resize handler
    useEffect(() => {
        const handleResize = () => {
            if (resizeTimeout.current) clearTimeout(resizeTimeout.current);
            resizeTimeout.current = setTimeout(() => {
                setResolution(new THREE.Vector2(size.width, size.height));
            }, 100); // Increased debounce time
        };

        handleResize(); // Initial set
        window.addEventListener("resize", handleResize);
        return () => {
            window.removeEventListener("resize", handleResize);
            if (resizeTimeout.current) clearTimeout(resizeTimeout.current);
        };
    }, [size]);

    useEffect(() => {
        console.log("Resolution updated:", resolution.x, resolution.y);
    }, [resolution]);

    useFrame(({ clock }) => {
        if (materialRef.current) {
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();
            // Only update if resolution actually changed
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
            <planeGeometry args={[viewport.width, viewport.height]} />{" "}
            {/* Use viewport dimensions */}
            <shaderMaterial
                ref={materialRef}
                uniforms={{
                    iTime: { value: 0 },
                    iResolution: { value: resolution },
                }}
                fragmentShader={metaballShader}
                vertexShader={`
                    varying vec2 vUv;
                    void main() {
                        vUv = position.xy * 0.5 + 0.5;
                        gl_Position = vec4(position, 1.0);
                    }
                `}
                key={resolution.x + "-" + resolution.y} // Force new material on significant resize
            />
        </mesh>
    );
}
