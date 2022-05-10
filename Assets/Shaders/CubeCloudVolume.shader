Shader "Unlit/CubeCloudVolume"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Back
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldVertex : TEXCOORD0;
            };

            // -----------------------------------------------------------------------
            // Vertex shader

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            // -----------------------------------------------------------------------
            // Globals

            sampler2D _MainTex;
            // sampler3D _NoiseTexture;

            // The name "NoiseTexture" needs to be same for texture and sampler
            Texture3D<float4> NoiseTexture;
            SamplerState samplerNoiseTexture;

            int _Steps;
            float _StepSize;
            float _DensityScale;
            float4 _Sphere;
            float _SphereRadius;
            float3 _Offset;

            // -----------------------------------------------------------------------
            // Functions

            float sdfSphere(float3 p, float3 sphere, float radius) {
                return length(p - sphere) - radius;
            }

            float rayMarch(float3 rayOrigin, float3 rayDir) {

                float density = 0;

                for(int i = 0; i < _Steps; i++) {

                    float sampleDensity = NoiseTexture.SampleLevel(
                        samplerNoiseTexture, rayOrigin, 0
                    ).r;
                    density += sampleDensity * _DensityScale;

                    /*
                    // Now we want to sample the volume at our new position
                    float distance = sdfSphere(rayOrigin, _Sphere.xyz, _SphereRadius);

                    if(distance < 0) {
                        // Inside sphere
                        // Grab the density of the sphere
                        float sampleDensity = tex3D(_NoiseTexture, rayOrigin + _Offset).r;
                        density += sampleDensity * _DensityScale;
                    }
                    */

                    rayOrigin += rayDir * _StepSize;
                }

                return exp(-density);
            }
            
            // -----------------------------------------------------------------------
            // Fragment shader

            fixed4 frag (v2f i) : SV_Target
            {
                // The ray origin will be a vector from the camera to the world vertex
                float3 rayOrigin = i.worldVertex;
                float3 rayDir = rayOrigin - _WorldSpaceCameraPos;

                float density = rayMarch(rayOrigin, rayDir);
                density = max(0, min(1, density));
                float4 col = float4(density,density,density,density);
                return col;
            }
            ENDCG
        }
    }
}
