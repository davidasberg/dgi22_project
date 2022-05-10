using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[CustomEditor(typeof(NoiseGen))]
public class NoiseGenEditor : Editor {

    NoiseGen noiseGen;



    public override void OnInspectorGUI() {
    
        DrawDefaultInspector();

        if (GUILayout.Button("Generate Noise To Texture File")) {
            noiseGen.ManualUpdateNoise();
            noiseGen.SaveNoiseToFile();
        }
    
    }

    void OnEnable () {
        noiseGen = (NoiseGen) target;
    }
}
