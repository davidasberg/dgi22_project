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

    [Header("Base Shape Settings")]
    public float containerEdgeFadeDst;
    public float cloudScale;
    public Vector3 cloudOffset;
    public float densityOffset;
    public Vector4 shapeNoiseWeights;

    [Header("Detail Settings")]
    public Vector4 detailNoiseWeights;
    public float detailNoiseScale;
    public Vector3 detailOffset;
    public float detailSpeed;
    public float detailNoiseWeight;

    [Header("Animation")]
    public float animationSpeed;
    public float baseCloudSpeed;

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

        // Ray marching settings
        material.SetFloat("_Steps", steps);
        material.SetFloat("_StepSize", stepSize);
        material.SetFloat("_DensityScale", densityScale);
        material.SetFloat("_ContainerEdgeFadeDst", containerEdgeFadeDst);

        // Light march settings
        material.SetInt("_LightSteps", lightSteps);
        material.SetFloat("_LightStepSize", lightStepSize);
        material.SetFloat("_LightDensityScale", lightDensityScale);
        material.SetFloat("_LightAbsorbation", lightAbsorbation);
        material.SetFloat("_LightDarknessThreshold", lightDarknessThreshold);
        material.SetFloat("_LightTransmittance", lightTransmittance);

        // Pos + Bounds
        material.SetVector("_Pos", transform.position);
        material.SetVector("_BoundsMax", transform.position + transform.localScale / 2.0f);
        material.SetVector("_BoundsMin", transform.position - transform.localScale / 2.0f);

        // Flow speed
        material.SetFloat("_TimeScale", Time.timeScale * animationSpeed);

        //Base Noise settings
        material.SetVector("_ShapeNoiseWeights", shapeNoiseWeights);
        material.SetVector("_CloudOffset", cloudOffset);
        material.SetVector("_DetailNoiseWeights", detailNoiseWeights);
        material.SetFloat("_DensityOffset", densityOffset);
        material.SetFloat("_CloudScale", cloudScale);
        material.SetFloat("_BaseCloudSpeed", baseCloudSpeed);

        // Detail
        material.SetFloat("_DetailNoiseScale", detailNoiseScale);
        material.SetVector("_DetailOffset", detailOffset);
        material.SetFloat("_DetailSpeed", detailSpeed);
        material.SetFloat("_DetailNoiseWeight", detailNoiseWeight);
        
        // Textures
        material.SetTexture("NoiseTexture", noiseGen.shapeTexture);
        material.SetTexture("DetailTexture", noiseGen.detailTexture);

        meshRenderer.material = material;
    }
}
