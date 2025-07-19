import { Canvas } from "@react-three/fiber";
import { MetaballPlane } from "./components/MetaballPlane";
import "./index.css";

function App() {
    return (
        <Canvas
            gl={{ antialias: true }}
            onCreated={({ gl }) => {
                gl.setPixelRatio(window.devicePixelRatio);
                gl.setSize(window.innerWidth, window.innerHeight);
            }}
        >
            <MetaballPlane />
        </Canvas>
    );
}

export default App;
