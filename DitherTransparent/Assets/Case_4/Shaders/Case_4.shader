Shader "DitherTransparent/Case_4" 
{
	Properties 
	{
		_DitherTexture ("Dither Texture", 2D) = "white" {}
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
			
			TEXTURE2D(_DitherTexture);
			SAMPLER(sampler_PointRepeat);
			float4 _DitherTexture_TexelSize;

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
				float2 uv = IN.positionCS.xy * _DitherTexture_TexelSize.xy;
				float dither_map = SAMPLE_TEXTURE2D(_DitherTexture, sampler_PointRepeat, uv).r;
				float ref_alpha = (dither_map * 0.99) + 0.01;

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