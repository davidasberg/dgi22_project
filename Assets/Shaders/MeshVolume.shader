Shader "Unlit/MeshVolume"
{
    Properties
    {
        
    }
    SubShader
    {
        Cull Off ZWrite Off
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Maximum amount of raymarching samples
            #define MAX_STEP_COUNT 128

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = v.uv;

                // Calculate vector from camera to vertex in world space
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));

                o.vertex = v.vertex;
                return o;
            }

            sampler3D _3DTexture;

            float _DensityThreshold;
            float _DensityMultiplier;

            // Cloud container bounds
            float4 _BoundsMin;
            float4 _BoundsMax;

            float4 BlendUnder(float4 color, float4 newColor)
            {
                color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
                color.a += (1.0 - color.a) * newColor.a;
                return color;
            }

            // Returns distance to our cloud container box, and how far inside the box we are.
            // If ray misses the box the distance inside will be 0.
            float2 sdfBox(float3 boundsMin, float3 boundsMax, float3 ro, float3 invRd) {
                // Adapted from: http://jcgt.org/published/0007/03/04/
                float3 t0 = (boundsMin - ro) * invRd;
                float3 t1 = (boundsMax - ro) * invRd;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                // CASE 1: ray intersects box from outside (0 <= dstA <= dstB)
                // dstA is dst to nearest intersection, dstB dst to far intersection

                // CASE 2: ray intersects box from inside (dstA < 0 < dstB)
                // dstA is the dst to intersection behind the ray, dstB is dst to forward intersection

                // CASE 3: ray misses box (dstA > dstB)

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // Start raymarching at the front surface of the object
                float3 rayPos = i.vertex;

                // Use vector from camera to object surface to get ray direction
                float3 rayDir = normalize(i.viewVector);

                // Check if ray hit the bounding box, this way we only render what is inside this volume
                float2 intersectInfo = sdfBox(_BoundsMin.xyz, _BoundsMax.xyz, rayPos, 1/rayDir);
                float dstToBox = intersectInfo.x;
                float dstInsideBox = intersectInfo.y;

                // First point of intersection
                float3 entryPoint = rayPos + rayDir * dstToBox;

                if(dstInsideBox > 0 + 0.01) {
                    return float4(0,0,0, 1);
                }


                float4 color = float4(0, 0, 0, 0);
                float3 samplePosition = entryPoint;
                float totalDensity = 0;

                // Raymarch through object space
                for (int i = 0; i < MAX_STEP_COUNT; i++)
                {
                    // Accumulate color only within unit cube bounds
                    if(max(abs(samplePosition.x), max(abs(samplePosition.y), abs(samplePosition.z))) < 0.5f + 0.01)
                    {
                        float4 sampledColor = tex3D(_3DTexture, samplePosition + float3(0.5f, 0.5f, 0.5f));
                        sampledColor.a *= 0.02;
                        color = BlendUnder(color, sampledColor) * _DensityMultiplier;
                        totalDensity += -3;
                        samplePosition += rayDir * 0.001;
                    }
                }

                float lightTransmittance = max(min(exp(-totalDensity), 1), 0);

                return color * lightTransmittance;
            }
            ENDCG
        }
    }
}
