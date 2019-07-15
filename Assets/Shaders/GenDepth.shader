// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/ShadowDepth"
{
	Properties
	{
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" }
		LOD 150
		Fog { Mode Off }

		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 pos2 : TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.pos2 = o.pos;
				return o;
			}

			float4 frag(v2f i) : Color
			{
				float depth = i.pos2.z / i.pos2.w;
				// convert OpenGL z range from -1..1 to 0..1
				#if !defined(SHADER_API_D3D9) && !defined(SHADER_API_D3D11) && !defined(SHADER_API_D3D11_9X)
					depth = depth * 0.5 + 0.5;
				#endif


				#if defined(UNITY_REVERSED_Z)
					depth = 1.0 - depth;
				#endif

				float4 color = EncodeFloatRGBA(depth);

				return color;
			}
			ENDCG
		}
	}
}
