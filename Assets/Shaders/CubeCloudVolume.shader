Shader "Unlit/CubeCloudVolume"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        
        ZWrite Off 
        ZTest Always
        Blend OneMinusSrcAlpha OneMinusSrcAlpha
        Tags { 
            "Queue" = "Transparent" 
            "RenderType" = "Transparent" 
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        Pass
        {
            HLSLPROGRAM
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
                float2 uv : TEXCOORD1;
            };

            // -----------------------------------------------------------------------
            // Vertex shader

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;

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
            float3 _Pos;
            float4 _ShapeNoiseWeights;
            float4 _DetailNoiseWeights;
            float _DensityOffset;
            float3 _Bounds;
            float _TimeScale;
            float _CloudScale;
            float _DetailNoiseScale;
            float3 _DetailOffset;
            float _DetailSpeed;
            float _DetailNoiseWeight;
            float _CloudOffset;
            float _BaseCloudSpeed;
            float3 _BoundsMax;
            float3 _BoundsMin;

            // Light
            int _LightSteps;
            float _LightStepSize;
            float _LightDensityScale;
            float _LightAbsorbation;
            float _LightDarknessThreshold;
            float _LightTransmittance;
            float4 _LightColor0;

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

            // Returns (dstToBox, dstInsideBox). If ray misses box, dstInsideBox will be zero
            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRaydir) {
                // Adapted from: http://jcgt.org/published/0007/03/04/
                
                float3 t0 = (boundsMin - rayOrigin) * invRaydir;
                float3 t1 = (boundsMax - rayOrigin) * invRaydir;
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

            float sampleDensity(float3 p) {
            
                // Calculate texture sample positions
                const float baseScale = 1/1000.0;
                const float offsetSpeed = 1/100.0;

                float time = _Time.x * _TimeScale;
                // float boundsMin = _Pos - _Bounds / 2;
                // float boundsMax = _Pos + _Bounds / 2;
                float size = _BoundsMax - _BoundsMin;
                float3 boundsCentre = (_BoundsMax+_BoundsMin) * .5;
                float3 uvw = (size * .5 + p) * baseScale * _CloudScale;
                float3 shapeSamplePos = uvw + _CloudOffset * offsetSpeed + float3(time,time*0.1,time*0.2) * _BaseCloudSpeed;

                const float containerEdgeFadeDst = 100;
                float dstFromEdgeX = min(containerEdgeFadeDst, min(p.x - _BoundsMin.x, _BoundsMax.x - p.x));
                float dstFromEdgeZ = min(containerEdgeFadeDst, min(p.z - _BoundsMin.z, _BoundsMax.z - p.z));
                float edgeWeight = min(dstFromEdgeZ,dstFromEdgeX)/containerEdgeFadeDst;

                float4 noise_from_shape = NoiseTexture.SampleLevel(samplerNoiseTexture, shapeSamplePos, 0);
                float4 noise_weights_normalized = _ShapeNoiseWeights / dot(_ShapeNoiseWeights, 1);

                //not sure what this does
                float4 noise_fbm = dot(noise_from_shape, noise_weights_normalized) ;
                float base_density = (noise_fbm + _DensityOffset * .1) * edgeWeight ;
                if (base_density > 0) {
                    // Sample detail noise
                    float3 detailSamplePos = uvw * _DetailNoiseScale + _DetailOffset * offsetSpeed + float3(time*.4,-time,time*0.1) * _DetailSpeed;
                    float4 detailNoise = DetailTexture.SampleLevel(samplerDetailTexture, detailSamplePos, 0);
                    float3 normalizedDetailWeights = _DetailNoiseWeights / dot(_DetailNoiseWeights, 1);
                    float detailFBM = dot(detailNoise, normalizedDetailWeights);

                    // Subtract detail noise from base shape (weighted by inverse density so that edges get eroded more than centre)
                    float oneMinusShape = 1 - noise_fbm;
                    float detailErodeWeight = oneMinusShape * oneMinusShape * oneMinusShape;
                    float cloudDensity = base_density - (1-detailFBM) * detailErodeWeight * _DetailNoiseWeight;
    
                    return max(0, cloudDensity * _DensityScale * 0.1);
                }
                return 0;
            }

            float3 rayMarch(float3 rayOrigin, float3 rayDir, float stepSize) {

                float density = 0;
                float transmission = 0; 
                float accumulatedLight = 0;
                float transmittance = _LightTransmittance;
                float light = 0;

                for(int i = 0; i < _Steps; i++) {

                    density += sampleDensity(rayOrigin) * stepSize;

                    // Light ray marching
                    float3 lightRay = rayOrigin;
                    float3 lightDir = normalize(_WorldSpaceLightPos0);
                    float2 rayBoxInfo = rayBoxDst(_BoundsMin, _BoundsMax, rayOrigin, 1/lightDir);
                    float lightDst = rayBoxInfo.x;
                    float lightInsideBox = rayBoxInfo.y;
                    float lightStepSize = lightInsideBox / _LightSteps;
                    for(int j = 0; j < _LightSteps; j++) {
                        float lightDensity = sampleDensity(lightRay);
                        accumulatedLight += max(0,lightDensity * _LightDensityScale * lightStepSize);

                        lightRay += lightDir * lightStepSize;
                    }

                    float lightTransmission = exp(-accumulatedLight);
                    float shadow = _LightDarknessThreshold + lightTransmission * (1 - _LightDarknessThreshold);
                    transmittance *= exp(-density * _LightAbsorbation);
                    light += density * transmittance * shadow;

                    rayOrigin += rayDir * stepSize;
                }

                return float3(light, density, transmittance);
            }   
            
            // -----------------------------------------------------------------------
            // Fragment shader

            fixed4 frag (v2f i) : SV_Target
            {
                // The ray origin will be a vector from the camera to the world vertex
                float3 rayOrigin = i.worldVertex;
                float3 rayDir = normalize(rayOrigin - _WorldSpaceCameraPos);
                
                float2 rayBoxInfo = rayBoxDst(_BoundsMin, _BoundsMax, _WorldSpaceCameraPos, 1/rayDir);
                float dstInsideBox = rayBoxInfo.y; // How long the ray lives inside the box

                // we only want to march while inside the box with _Steps number of steps which 
                // all are equally distribuated along the ray.
                float stepSize = dstInsideBox / _Steps;
                float3 result = rayMarch(rayOrigin, rayDir, stepSize);

                float light = result.x;
                float density = result.y;
                float transmittance = result.z;
                density = max(0, min(1, density));

                // float3 col = tex2D(_MainTex, i.uv);
                float3 col = light * _LightColor0.rgb;
                //return float4(col,density);
                return float4(col,density);
                //return col;
            }
            ENDHLSL
        }
    }
}
