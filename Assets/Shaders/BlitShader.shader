Shader "Unlit/BlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _3DTexture ("3DTexture", 3D) = "white" {}
        _BoundsMin ("Bounds Min", Vector) = (0,0,0,0)
        _BoundsMax ("Bounds Max", Vector) = (1,1,1,1)

        _DensityThreshold ("Density Threshold", Float) = 1
        _DensityMultiplier ("Cloud Density", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float3 viewVector : TEXCOORD1;
                float3 texcoord : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.texcoord = v.vertex.xyz;

                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                
                return o;
            }

            // -----------------------------------------------------------------------
            // Globals

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            // Textures
            sampler3D _3DTexture;

            // Cloud container bounds (set in material)
            float4 _BoundsMin;
            float4 _BoundsMax;

            float _DensityThreshold;
            float _DensityMultiplier;

            // -----------------------------------------------------------------------
            // Functions
            
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

            // for now it only reads our 3D texture at ray position and accumulate the density
            float sampleDensity(float3 rayPos) {
                float4 sample = tex3D(_3DTexture, rayPos);
                // sample *= 0.001;
                float density = max(0, sample.r + _DensityThreshold) * _DensityMultiplier;
                return density;
            }

            // -----------------------------------------------------------------------
            // Fragment shader

            fixed4 frag (v2f i) : SV_Target
            {
                // Create the ray starting from the camera
                float3 rayPos = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);

                // Read z-buffer texture for depth check when rendering
                float viewLength = length(i.viewVector);
                float nonlin_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonlin_depth) * viewLength;

                // Check if ray hit the bounding box, this way we only render what is inside this volume
                float2 intersectInfo = sdfBox(_BoundsMin.xyz, _BoundsMax.xyz, rayPos, 1/rayDir);
                float dstToBox = intersectInfo.x;
                float dstInsideBox = intersectInfo.y;

                // First point of intersection
                float3 entryPoint = rayPos + rayDir * dstToBox;

                // Ray marching config parameters
                const float stepSize = 0.01;
                float dstTravelled = 0;
                float dstLimit = min(depth - dstToBox, dstInsideBox);

                float4 cloudColor = float4(0,0,0,0);
                float totalDensity = 0;

                // Ray march through the box volume and accumulate color
                // the [loop] attribute tells the compiler this is a loop (slow code) which can not be unwraped
                // ref: https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-for
                [loop] while(dstTravelled < dstLimit) {
                    rayPos = entryPoint + rayDir * dstTravelled;
                    totalDensity += sampleDensity(rayPos);
                    cloudColor = tex3D(_3DTexture, rayPos);
                    dstTravelled += stepSize;
                }
                float lightTransmittance = max(min(exp(-totalDensity), 1), 0);

                // Due to we have a Blit shader we need to sample the rest of the image and draw it aswell
                float4 col = tex2D(_MainTex, i.uv);
                col *= lightTransmittance;
                return col;
            }
            ENDCG
        }
    }
}
