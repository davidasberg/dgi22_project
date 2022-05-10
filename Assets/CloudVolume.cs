using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CloudVolume : MonoBehaviour
{
    public Shader clouds;
    public Texture3D noiseTexture;

    public float densityThreshold;
    public float densityMultiplier;

    private MeshRenderer containerMesh;
    private Material meshMaterial;

    private void Start()
    {
        containerMesh = GetComponent<MeshRenderer>();

        if (meshMaterial == null)
            meshMaterial = new Material(clouds);
    }

    private void Update()
    {
        // Bounds
        Vector3 min = transform.position - transform.localScale / 2;
        Vector3 max = transform.position + transform.localScale / 2;
        meshMaterial.SetVector("_BoundsMin", min);
        meshMaterial.SetVector("_BoundsMax", max);

        // Textures
        meshMaterial.SetTexture("_3DTexture", noiseTexture);

        // Parameters
        meshMaterial.SetFloat("_DensityThreshold", densityThreshold);
        meshMaterial.SetFloat("_DensityMultiplier", densityMultiplier);

        // Set material to container mesh
        containerMesh.material = meshMaterial;
    }
}
