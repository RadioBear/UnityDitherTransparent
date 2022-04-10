Shader "DitherTransparent/Case_2" 
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

				float2 uv = floor(IN.positionCS.xy);
                float noise = frac(1000 * cos(dot(uv.xy, float2(347.834503, 3343.28369))));

                if (alpha < noise) discard;
				
				return _BaseColor;
			}
			ENDHLSL
		}
	}
}