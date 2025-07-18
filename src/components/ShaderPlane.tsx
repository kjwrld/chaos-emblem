import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

export default function ShaderPlane() {
    const meshRef = useRef<THREE.Mesh>(null!);

    useFrame(() => {});

    return (
        <mesh ref={meshRef}>
            <planeGeometry args={[2, 2]} />
            <shaderMaterial
                fragmentShader={`void main() { gl_FragColor = vec4(0.0, 0.5, 1.0, 1.0); }`}
                vertexShader={`void main() { gl_Position = vec4(position, 1.0); }`}
            />
        </mesh>
    );
}
