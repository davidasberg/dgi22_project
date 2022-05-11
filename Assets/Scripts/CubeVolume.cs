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

    [Header("Light March Settings")]
    public int lightSteps;
    public float lightStepSize;
    public float lightDensityScale;
    public float lightAbsorbation;
    public float lightDarknessThreshold;
    public float lightTransmittance = 1;

    [Header("Shape Settings")]
    public Vector4 shapeNoiseScale;
    public float densityOffset;
    
    [Header("Detail Settings")]
    public Vector4 detailNoiseScale;

    public Vector3 textureOffset;

    public Shader shader;

    private MeshRenderer meshRenderer;
    private Material material;

    private NoiseGen noiseGen;



    private void Start()
    {
        meshRenderer = GetComponent<MeshRenderer>();
        noiseGen = GetComponent<NoiseGen>();

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

        // Light march settings
        material.SetInt("_LightSteps", lightSteps);
        material.SetFloat("_LightStepSize", lightStepSize);
        material.SetFloat("_LightDensityScale", lightDensityScale);
        material.SetFloat("_LightAbsorbation", lightAbsorbation);
        material.SetFloat("_LightDarknessThreshold", lightDarknessThreshold);
        material.SetFloat("_LightTransmittance", lightTransmittance);

        material.SetVector("_Offset", textureOffset);

        // Bounds
        material.SetVector("_Bounds", new Vector3(transform.localScale.x, transform.localScale.y, transform.localScale.z));

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
