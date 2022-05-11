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
    public float cloudScale;
    public Vector3 cloudOffset;
    public float densityOffset;
    public Vector4 shapeNoiseWeights;
    
    [Header("Detail Settings")]
    public Vector4 detailNoiseWeights;

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


        // Pos
        material.SetVector("_Pos", transform.position);

        // Bounds
        material.SetVector("_Bounds", new Vector3(transform.localScale.x, transform.localScale.y, transform.localScale.z));

        // Flow speed
        material.SetFloat("_TimeScale", Time.timeScale * animationSpeed);

        //Base Noise settings
        material.SetVector("_ShapeNoiseWeights", shapeNoiseWeights);
        material.SetVector("_CloudOffset", cloudOffset);
        material.SetVector("_DetailNoiseWeights", detailNoiseWeights);
        material.SetFloat("_DensityOffset", densityOffset);
        material.SetFloat("_CloudScale", cloudScale);
        material.SetFloat("_BaseCloudSpeed", baseCloudSpeed);


        // Textures
        material.SetTexture("NoiseTexture", noiseGen.shapeTexture);
        material.SetTexture("DetailTexture", noiseGen.detailTexture);
        

        meshRenderer.material = material;
    }
}
