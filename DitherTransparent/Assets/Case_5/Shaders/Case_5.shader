Shader "DitherTransparent/Case_5" 
{
	Properties 
	{
		_BaseColor ("_BaseColor", Color) = (0, 0.66, 0.73, 1)
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
			
			float DitheredFilter(float2 cpos)
			{
				// Define a dither threshold matrix which can
				// be used to define how a 4x4 set of pixels
				// will be dithered
				float DITHER_THRESHOLDS[16] =
				{
					1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
					13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
					4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
					16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
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
				float ref_alpha = DitheredFilter(IN.positionCS.xy);

				// Gradient-Intercept Equation Form
				// y = mx + b
				half far_result = saturate(_FarGradient * IN.uv.z + _FarIntercept);
				half near_result = saturate(_NearGradient * IN.uv.z + _NearIntercept);
				half result = lerp(far_result, near_result, _MiddleAlpha);
				if(result < ref_alpha)
					discard;
				
				return _BaseColor;
			}
			ENDHLSL
		}
	}
}