using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CubeVolume : MonoBehaviour
{
    [Header("Ray March Settings")]
    public int steps;
    public float stepSize;
    public float densityScale;

    [Header("Shape Settings")]
    public Vector4 shapeNoiseScale;
    public float densityOffset;
    
    [Header("Detail Settings")]
    public Vector4 detailNoiseScale;

    

    public Vector3 textureOffset;
    // public Texture3D noiseTexture;

    public Shader shader;

    private MeshRenderer meshRenderer;
    private Material material;

    private NoiseGen noiseGen;

    private void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        noiseGen = GetComponent<NoiseGen>();

        if (noiseGen == null)
            Debug.Log("NULL");

        noiseGen.updateNoise = true;

        if (material == null)
            material = new Material(shader);
    }

    private void Update()
    {
        noiseGen.GenerateNoise();

        // get radius (depening on volume scale)
        float radius = transform.localScale.x / 3;
        material.SetFloat("_SphereRadius", radius);

        // Ray marching settings
        material.SetFloat("_Steps", steps);
        material.SetFloat("_StepSize", stepSize);
        material.SetFloat("_DensityScale", densityScale);

        material.SetVector("_Offset", textureOffset);

        // Noise settings
        material.SetVector("_ShapeNoiseScale", shapeNoiseScale);
        material.SetVector("_DetailNoiseScale", detailNoiseScale);
        material.SetFloat("_DensityOffset", densityOffset);

        // Textures
        material.SetTexture("NoiseTexture", noiseGen.shapeTexture);
        material.SetTexture("DetailTexture", noiseGen.detailTexture);
        

        meshRenderer.material = material;
    }
}
