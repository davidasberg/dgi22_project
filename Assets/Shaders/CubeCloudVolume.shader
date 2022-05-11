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

            Texture3D<float4> NoiseTexture;
            SamplerState samplerNoiseTexture;
            
            Texture3D<float4> DetailTexture;
            SamplerState samplerDetailTexture;

            int _Steps;
            float _StepSize;
            float _DensityScale;
            float4 _Sphere;
            float _SphereRadius;
            float3 _Offset;
            float4 _ShapeNoiseScale;
            float4 _DetailNoiseScale;
            float _DensityOffset;
            float3 _Bounds;

            // Light
            int _LightSteps;
            float _LightStepSize;
            float _LightDensityScale;
            float _LightAbsorbation;
            float _LightDarknessThreshold;
            float _LightTransmittance;

            // -----------------------------------------------------------------------
            // Functions

            float sdfSphere(float3 p, float3 sphere, float radius) {
                return length(p - sphere) - radius;
            }

            float sdBox( float3 p, float3 b )
            {
                float3 q = abs(p) - b;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }

            float sdRoundBox( float3 p, float3 b, float r )
            {
                float3 q = abs(p) - b;
                return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
            }

            float sampleDensity(float3 p) {
                
                float4 noise_from_shape = NoiseTexture.SampleLevel(samplerNoiseTexture, p, 0);
                float4 noise_weights_normalized = _ShapeNoiseScale / dot(_ShapeNoiseScale, 1);

                //not sure what this does
                float4 noise_fbm = dot(noise_from_shape, noise_weights_normalized);
                float base_density = noise_fbm + _DensityOffset * .1 ;
                if (base_density > 0) {
                    return base_density * _DensityScale * .1;
                }
                return 0;
            }

            float3 rayMarch(float3 rayOrigin, float3 rayDir) {

                float density = 0;
                float transmission = 0; 
                float accumulatedLight = 0;
                float transmittance = _LightTransmittance;
                float light = 0;

                for(int i = 0; i < _Steps; i++) {

                    // Now we want to sample the volume at our new position
                    //float distance = sdfSphere(rayOrigin, _Sphere.xyz, _SphereRadius);
                    float distance = sdRoundBox(rayOrigin, _Bounds, 0.05);
                    if(distance < 0) {
                        density += sampleDensity(rayOrigin);

                        // Light ray marching
                        float3 lightRay = rayOrigin;
                        float3 lightDir = normalize(_WorldSpaceLightPos0 - lightRay);
                        for(int j = 0; j < _LightSteps; j++) {
                            float lightDensity = sampleDensity(lightRay);
                            accumulatedLight += lightDensity * _LightDensityScale;

                            lightRay += lightDir * _LightStepSize;
                        }

                        float lightTransmission = exp(-accumulatedLight);
                        float shadow = _LightDarknessThreshold + lightTransmission * (1 - _LightDarknessThreshold);
                        light += density * transmittance * shadow;
                        transmittance *= exp(-density * _LightAbsorbation);
                    }
                    rayOrigin += rayDir * _StepSize;
                }

                return float3(light, density, transmittance);
            }
            
            // -----------------------------------------------------------------------
            // Fragment shader

            fixed4 frag (v2f i) : SV_Target
            {
                // The ray origin will be a vector from the camera to the world vertex
                float3 rayOrigin = i.worldVertex;
                float3 rayDir = rayOrigin - _WorldSpaceCameraPos;
                float3 rayDirNormalized = normalize(rayDir);
                float3 result = rayMarch(rayOrigin, rayDirNormalized);
                float light = result.x;
                float density = result.y;
                float transmittance = result.z;
                // density = max(0, min(1, density));
                float4 col = float4(light,light,light,density);
                return col;
            }
            ENDCG
        }
    }
}
