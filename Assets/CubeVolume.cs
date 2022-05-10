using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CubeVolume : MonoBehaviour
{
    public int steps;
    public float stepSize;
    public float densityScale;

    public Vector4 sphere;

    public Shader shader;

    private MeshRenderer meshRenderer;
    private Material material;
    
    private void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();

        if (material == null)
            material = new Material(shader);
    }

    private void Update()
    {
        material.SetFloat("_Steps", steps);
        material.SetFloat("_StepSize", stepSize);
        material.SetVector("_Sphere", sphere);

        material.SetFloat("_DensityScale", densityScale);

        meshRenderer.material = material;
    }
}
