Shader "Unlit/DemoShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Back ZWrite Off ZTest Always
        Tags { 
            "Queue" = "Transparent" 
            "RenderType" = "Transparent" 
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            sampler2D _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldPos = worldPos;

                return o;
            }

            #define STEPS 1024
            #define STEP_SIZE 0.001
            #define DENSITY 0.001

            Texture3D<float4> NoiseTexture;
            SamplerState samplerNoiseTexture;

            float sdfSphere(float3 p, float3 sphere, float radius) {
                return length(p - sphere) - radius;
            }

            float sampleDensity1(float3 samplePos) {
                float density = NoiseTexture.SampleLevel(samplerNoiseTexture, samplePos, 0).r;
                if(density > 0) {
                    return density * DENSITY;
                }
                return 0;
            }

            float4 _ShapeNoiseWeights;
            float4 _DetailNoiseWeights;
            float _DensityOffset;
            float _DensityScale;
            float sampleDensity2(float3 samplePos) {

                float4 noise_from_shape = NoiseTexture.SampleLevel(samplerNoiseTexture, samplePos, 0);
                float4 noise_weights_normalized = _ShapeNoiseWeights / dot(_ShapeNoiseWeights, 1);

                //not sure what this does
                float4 noise_fbm = dot(noise_from_shape, noise_weights_normalized);
                float base_density = noise_fbm + _DensityOffset * .1 ;
                if (base_density > 0) {
                    return base_density * _DensityScale * .1;
                }
                return 0;
            }

            fixed4 frag (v2f i) : SV_Target
            {   
                float3 rayOrigin = i.worldPos;
                float3 rayDir = normalize(rayOrigin - _WorldSpaceCameraPos);

                // Ray march along our line and accumulate color
                float3 color = float3(0,0,0);
                for(int i = 0; i < STEPS; i++) {

                    float distance = sdfSphere(rayOrigin, float3(0,0,0), 0.4);

                    // Only accumulate color if we are inside the sphere
                    if(distance < 0) {
                        color += sampleDensity2(rayOrigin);
                    }

                    rayOrigin += rayDir * STEP_SIZE;
                }

                return float4(color, 0);
            }
            ENDCG
        }
    }
}
