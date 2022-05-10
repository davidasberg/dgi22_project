using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class NoiseGen : MonoBehaviour
{

    [Header("Noise Settings")]
    public int shapeRes = 128;
    public int detailRes = 32;

    public WorleySettings[] shapeSettings;
    public WorleySettings[] detailSettings;
    public ComputeShader worleyCompute;

    [SerializeField]
    public RenderTexture shapeTexture;
    [SerializeField]
    public RenderTexture detailTexture;


    [Header("Update Settings")]
    private bool updateNoise;

    //internal 
    private List<ComputeBuffer> buffersToRelease = new List<ComputeBuffer>();
    const int computeThreadGroupSize = 8;

    public void ManualUpdateNoise()
    {
        updateNoise = true;
        GenerateNoise();
    }

    public void GenerateNoise() {
        CreateTexture(ref shapeTexture, shapeRes, "ShapeTexture");
        CreateTexture(ref detailTexture, detailRes, "DetailTexture");
        if (updateNoise) {
            updateNoise = false;
            for (int i = 0; i < shapeSettings.Length; i++)
                WorleyNoise(shapeSettings[i], ref shapeTexture, i);
            for (int i = 0; i < detailSettings.Length; i++)
                WorleyNoise(detailSettings[i], ref detailTexture, i);
            
            // Release buffers
            foreach (var buffer in buffersToRelease) {
                buffer.Release ();
            }
        }
    }

    public void WorleyNoise(WorleySettings noiseSettings, ref RenderTexture output, int channel) {

        // Send compute shader data
        // And dispatch compute shader kernel 0 (Worley Noise)
        worleyCompute.SetFloat("persistence", noiseSettings.persistence);
        worleyCompute.SetInt("res", output.width);
        worleyCompute.SetInt("channel", channel);
        worleyCompute.SetTexture(0, "Result", output);
        var minMaxBuffer = CreateBuffer(new int[] {int.MaxValue, 0}, sizeof(int), "minMax", 0);
        var random = new System.Random(noiseSettings.seed);
        CreateWorleyBuffer(random, noiseSettings.numDivisionsA, "pointsA");
        CreateWorleyBuffer(random, noiseSettings.numDivisionsB, "pointsB");
        CreateWorleyBuffer(random, noiseSettings.numDivisionsC, "pointsC");
        worleyCompute.SetInt("numDivisionsA", noiseSettings.numDivisionsA);
        worleyCompute.SetInt("numDivisionsB", noiseSettings.numDivisionsB);
        worleyCompute.SetInt("numDivisionsC", noiseSettings.numDivisionsC);
        worleyCompute.SetBool("inv", noiseSettings.invert);
        worleyCompute.SetInt("tile", noiseSettings.tile);
        worleyCompute.SetTexture (0, "Result", output);
        int numThreads = Mathf.CeilToInt(output.width / (float)computeThreadGroupSize);
        worleyCompute.Dispatch(0, numThreads, numThreads, numThreads);
        
        // Send min and max values to compute shader
        // And dispatch compute shader kernel 1 (Normalize)
        worleyCompute.SetBuffer(1, "minMax", minMaxBuffer);
        worleyCompute.SetTexture(1, "Result", output);
        worleyCompute.Dispatch(1, numThreads, numThreads, numThreads);
    }   


    // Create a 3D texture with resolution 
    // Uses large bit format to store values
    public void CreateTexture(ref RenderTexture texture, int res, string name) {
        var format = UnityEngine.Experimental.Rendering.GraphicsFormat.R16G16B16A16_UNorm;
        if (texture == null || texture.width != res || texture.height != res || texture.graphicsFormat != format || texture.volumeDepth != res || !texture.IsCreated()) {
            if (texture != null) {
                texture.Release();
            }
            texture = new RenderTexture(res, res, 0);   
            texture.graphicsFormat = format;
            texture.volumeDepth = res;
            texture.enableRandomWrite = true;
            texture.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            texture.name = name;
            texture.Create();
        }
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Bilinear;
    }

    public ComputeBuffer CreateBuffer(System.Array data, int stride, string name, int kernel = 0) {
    
        var buffer = new ComputeBuffer(data.Length, stride, ComputeBufferType.Structured);
        buffersToRelease.Add(buffer);
        buffer.SetData(data);
        worleyCompute.SetBuffer(kernel, name, buffer);
        return buffer;
    }

    public void CreateWorleyBuffer(System.Random random, int numDivs, string name) {
        var points = new Vector3[numDivs*numDivs*numDivs];
        float divSize = 1f / numDivs;
        for (int x = 0; x < numDivs; x++) {
            for (int y = 0; y < numDivs; y++) {
                for (int z = 0; z < numDivs; z++) {
                    float randX = (float) random.NextDouble();
                    float randY = (float) random.NextDouble();
                    float randZ = (float) random.NextDouble();
                    Vector3 pointRelative = new Vector3(randX, randY, randZ) * divSize;
                    Vector3 divOrigin = new Vector3(x, y, z) * divSize;
                    points[x + y * numDivs + z * numDivs * numDivs] = divOrigin + pointRelative;
                }
            }
        }
        CreateBuffer(points, sizeof(float)*3, name);
    }

    public void OnValidate() {
        updateNoise = true;
    }

    public void SaveNoiseToFile() {
        //write shape and detail textures to 3D Texture Asset
        //and save to file
        AssetDatabase.CreateAsset(shapeTexture, "Assets/Resources/Noise/ShapeTexture.asset");
        AssetDatabase.CreateAsset(detailTexture, "Assets/Resources/Noise/DetailTexture.asset");
    }

}
