import { Canvas } from "@react-three/fiber";
import { Suspense } from "react";
import ShaderPlane from "./components/ShaderPlane.tsx";
import "./index.css";

function App() {
    return (
        <Canvas orthographic camera={{ zoom: 100, position: [0, 0, 5] }}>
            <Suspense fallback={null}>
                <ShaderPlane />
            </Suspense>
        </Canvas>
    );
}

export default App;
