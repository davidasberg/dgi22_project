Shader "Unlit/CubeCloudVolume"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline"}
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
                float2 uv : TEXCOORD0;
                float3 worldVertex : TEXCOORD1;
            };

            sampler2D _MainTex;

            int _Steps;
            float _StepSize;

            float4 _Sphere;

            float _DensityScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            float sdfSphere(float3 p, float3 sphere, float radius) {
                return length(p - sphere) - radius;
            }

            float rayMarch(float3 rayOrigin, float3 rayDir) {

                float density;

                for(int i = 0; i < _Steps; i++) {

                    rayOrigin += rayDir * _StepSize;

                    // Now we want to sample the volume at our new position
                    float distance = sdfSphere(rayOrigin, _Sphere.xyz, _Sphere.w);

                    if(distance < 0) {
                        // Inside sphere
                        // Grab the density of the sphere
                        density += 0.1 * _DensityScale;
                    } 
                }

                return density;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // The ray origin will be a vector from the camera to the world vertex
                float3 rayOrigin = i.worldVertex;
                float3 rayDir = rayOrigin - _WorldSpaceCameraPos;

                float density = rayMarch(rayOrigin, rayDir);
                
                return float4(density,density,density,density);
            }
            ENDCG
        }
    }
}
