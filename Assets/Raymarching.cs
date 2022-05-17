using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Raymarching : MonoBehaviour
{
    public Shader shader;

    public float densityScale;
    public float densityOffset;

    public Vector4 shapeNoiseWeights;
    public Vector4 detailNoiseWeights;

    private NoiseGen noiseGen;
    private MeshRenderer meshRenderer;
    private Material material;

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

        // Pos
        material.SetVector("_Pos", transform.position);

        // Bounds
        material.SetVector("_Bounds", new Vector3(transform.localScale.x, transform.localScale.y, transform.localScale.z));

        // Textures
        material.SetTexture("NoiseTexture", noiseGen.shapeTexture);

        material.SetFloat("_DensityScale", densityScale);
        material.SetFloat("_DensityOffset", densityOffset);
        material.SetVector("_ShapeNoiseWeights", shapeNoiseWeights);
        material.SetVector("_DetailNoiseWeights", detailNoiseWeights);

        meshRenderer.material = material;
    }
}
