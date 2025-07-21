import { useFrame, useThree } from "@react-three/fiber";
import { useRef, useEffect, useState, useMemo } from "react";
import * as THREE from "three";
import metaballShader from "../shaders/metaballShader.glsl?raw";
import Stats from "stats.js";

export function MetaballPlane() {
    const materialRef = useRef<THREE.ShaderMaterial>(null);
    const { size, viewport } = useThree();
    const [resolution, setResolution] = useState(new THREE.Vector2());
    const resizeTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);
    const statsRef = useRef<Stats | null>(null);

    const CONTROLS = useMemo(
        () => ({
            ballCount: 250,
            speed: 1.0,
            spread: 0.5,
            size: 0.01,
            morphSpeed: 5.0,
            holdDuration: 15.0,
            transitionDuration: 5.0,
            overallDistortion: 0.0,
            vDistortionMultiplier: 0.0,
            lemniscateScale: 0.75,
            lemniscateScaleX: 0.5,
            lemniscateScaleY: 1.0,
            topWidthMultiplier: 2.0,
            bottomWidthMultiplier: 0.75,
            centerOffset: -0.1,
            asymmetryStrength: 0.75,
            starScale: 0.5,
            starInnerRadius: 0.75,
            starOuterRadius: 0.9,
            starRotation: 0.0,
        }),
        []
    );

    // Pre-create vectors and colors to avoid garbage collection
    const tempVec2 = useMemo(() => new THREE.Vector2(), []);
    const whiteColor = useMemo(() => new THREE.Color("#ffffff"), []);

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

        // Set initial resolution
        tempVec2.set(size.width, size.height);
        setResolution(tempVec2.clone());

        window.addEventListener("resize", handleResize);
        return () => {
            window.removeEventListener("resize", handleResize);
            if (resizeTimeout.current) {
                clearTimeout(resizeTimeout.current);
            }
        };
    }, [size, tempVec2]);

    const uniforms = useMemo(
        () => ({
            iTime: { value: 0 },
            iResolution: { value: new THREE.Vector2(size.width, size.height) },
            uSpeed: { value: CONTROLS.speed },
            uSpread: { value: CONTROLS.spread },
            uSize: { value: CONTROLS.size },
            uBallCount: { value: CONTROLS.ballCount },
            uColor: { value: whiteColor },
            uMorphSpeed: { value: CONTROLS.morphSpeed },
            uHoldDuration: { value: CONTROLS.holdDuration },
            uTransitionDuration: { value: CONTROLS.transitionDuration },
            uOverallDistortion: { value: CONTROLS.overallDistortion },
            uVDistortionMultiplier: { value: CONTROLS.vDistortionMultiplier },
            uLemniscateScale: { value: CONTROLS.lemniscateScale },
            uLemniscateAxisScale: {
                value: new THREE.Vector2(
                    CONTROLS.lemniscateScaleX,
                    CONTROLS.lemniscateScaleY
                ),
            },
            uTopWidthMultiplier: { value: CONTROLS.topWidthMultiplier },
            uBottomWidthMultiplier: { value: CONTROLS.bottomWidthMultiplier },
            uCenterOffset: { value: CONTROLS.centerOffset },
            uAsymmetryStrength: { value: CONTROLS.asymmetryStrength },
            uStarScale: { value: CONTROLS.starScale },
            uStarInnerRadius: { value: CONTROLS.starInnerRadius },
            uStarOuterRadius: { value: CONTROLS.starOuterRadius },
            uStarRotation: { value: CONTROLS.starRotation },
        }),
        [CONTROLS, size.width, size.height, whiteColor]
    );

    const vertexShader = useMemo(
        () => `
        varying vec2 vUv;
        void main() {
            vUv = position.xy * 0.5 + 0.5;
            gl_Position = vec4(position, 1.0);
        }
    `,
        []
    );

    useFrame(({ clock }) => {
        statsRef.current?.begin();

        if (materialRef.current) {
            // Only update time and resolution - everything else is static
            materialRef.current.uniforms.iTime.value = clock.getElapsedTime();

            // Only update resolution if it changed
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
                uniforms={uniforms}
                fragmentShader={metaballShader}
                vertexShader={vertexShader}
            />
        </mesh>
    );
}
