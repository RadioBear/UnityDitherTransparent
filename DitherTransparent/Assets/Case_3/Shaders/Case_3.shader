Shader "DitherTransparent/Case_3" 
{
	Properties 
	{
		_BaseColor ("_BaseColor", Color) = (0, 0.66, 0.73, 1)
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
		
		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			CBUFFER_END
		ENDHLSL
		
		Pass 
		{
			Tags { "LightMode"="UniversalForward" }
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv			: TEXCOORD0;
			};
			
			struct Varyings 
			{
				float4 positionCS 			: SV_POSITION;
				float2 uv					: TEXCOORD0;
			};
			
			TEXTURE2D(_DitherTexture);
			SAMPLER(sampler_PointRepeat);


			// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
			uint BobJenkinsHash(uint x)
			{
				x += (x << 10u);
				x ^= (x >> 6u);
				x += (x << 3u);
				x ^= (x >> 11u);
				x += (x << 15u);
				return x;
			}

			// Compound versions of the hashing algorithm.
			uint BobJenkinsHash(uint2 v)
			{
				return BobJenkinsHash(v.x ^ BobJenkinsHash(v.y));
			}

			// Construct a float with half-open range [0, 1) using low 23 bits.
			// All zeros yields 0, all ones yields the next smallest representable value below 1.
			float ConstructIEEEFloat(int m) 
			{
				const int ieeeMantissa = 0x007FFFFF; // Binary FP32 mantissa bitmask
				const int ieeeOne = 0x3F800000; // 1.0 in FP32 IEEE

				m &= ieeeMantissa;                   // Keep only mantissa bits (fractional part)
				m |= ieeeOne;                        // Add fractional part to 1.0

				float  f = asfloat(m);               // Range [1, 2)
				return f - 1;                        // Range [0, 1)
			}

			float ConstructIEEEFloat(uint m)
			{
				return ConstructIEEEFloat(asint(m));
			}


			// Pseudo-random value in half-open range [0, 1). The distribution is reasonably uniform.
			// Ref: https://stackoverflow.com/a/17479300
			float GenerateNoiseHashedRandomFloat(uint2 v)
			{
				return ConstructIEEEFloat(BobJenkinsHash(v));
			}

			Varyings vert(Attributes IN) 
			{
				Varyings OUT;
				
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv.xy = IN.uv.xy;
				return OUT;
			}
			
			half4 frag(Varyings IN) : SV_Target 
			{
                float alpha = abs(sin(_Time.y));

				float p = GenerateNoiseHashedRandomFloat(IN.positionCS.xy);
				if (alpha < p) discard;

				return _BaseColor;
			}
			ENDHLSL
		}
	}
}