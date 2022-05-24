using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[CustomEditor(typeof(NoiseGen))]
public class NoiseGenEditor : Editor {

    NoiseGen noiseGen;



    public override void OnInspectorGUI() {
    
        DrawDefaultInspector();

        if (GUILayout.Button("Update Noise")) {
            noiseGen.ManualUpdateNoise();
        }
    
    }

    void OnEnable () {
        noiseGen = (NoiseGen) target;
    }
}
