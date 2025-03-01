Shader "DitherTransparent/Case_6" 
{
	Properties 
	{
		_BaseColor ("_BaseColor", Color) = (0, 0.66, 0.73, 1)
		_BaseMap ("_BaseMap", 2D) = "black" {}
		_ClipAlpha ("_ClipAlpha", Float) = 0.5
		_FarGradient ("_FarGradient", Float) = 2.0
		_FarIntercept ("_FarIntercept", Float) = -3.0
		_NearGradient ("_NearGradient", Float) = 2.0
		_NearIntercept ("_NearIntercept", Float) = -1.0
		_MiddleAlpha ("_MiddleAlpha", Float) = 0.2
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
		
		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			CBUFFER_START(UnityPerMaterial)
			float4 _BaseColor;
			float _ClipAlpha;
			float _FarGradient;
			float _FarIntercept;
			float _NearGradient;
			float _NearIntercept;
			float _MiddleAlpha;
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
				float3 uv					: TEXCOORD0;
			};

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
			
			float DitheredFilter(float2 cpos)
			{
				// Define a dither threshold matrix which can
				// be used to define how a 4x4 set of pixels
				// will be dithered
				float DITHER_THRESHOLDS[16] =
				{
					0.031250,	   // 1.0 / 32.0
					0.531250,	   // 17.0 / 32.0
					0.156250,	   // 5.0 / 32.0
					0.656250,	   // 21.0 / 32.0
					0.781250,	   // 25.0 / 32.0
					0.281250,	   // 9.0 / 32.0
					0.906250,	   // 29.0 / 32.0
					0.406250,	   // 13.0 / 32.0
					0.218750,	   // 7.0 / 32.0
					0.718750,	   // 23.0 / 32.0
					0.093750,	   // 3.0 / 32.0
					0.593750,	   // 19.0 / 32.0
					0.968750,	   // 31.0 / 32.0
					0.468750,	   // 15.0 / 32.0
					0.843750,	   // 27.0 / 32.0
					0.343750,	   // 11.0 / 32.0
				};

				uint index = (uint(cpos.x) % 4) * 4 + uint(cpos.y) % 4;
				return DITHER_THRESHOLDS[index];
			}


			Varyings vert(Attributes IN) 
			{
				Varyings OUT;
				
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.uv.xy = IN.uv.xy;
                OUT.uv.z = distance(GetCameraPositionWS(), positionInputs.positionWS);
				return OUT;
			}
			
			half4 frag(Varyings IN) : SV_Target 
			{
				float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv.xy);
				float checkAlpha = baseMap.a - _ClipAlpha;
				float check = (checkAlpha < 0.0f) ? 1.0f : 0.0f;
				if (check != 0.0f)
					discard;
				float ref_alpha = DitheredFilter(IN.positionCS.xy);

				// Gradient-Intercept Equation Form
				// y = mx + b
				half far_result = saturate(_FarGradient * IN.uv.z + _FarIntercept);
				half near_result = saturate(_NearGradient * IN.uv.z + _NearIntercept);
				half result = lerp(far_result, near_result, _MiddleAlpha);
				if(result < ref_alpha)
					discard;
				
				float4 final_color;
				final_color.xyz = _BaseColor.xyz * baseMap.xyz;
				final_color.w = _BaseColor.w;
				return final_color;
			}
			ENDHLSL
		}
	}
}