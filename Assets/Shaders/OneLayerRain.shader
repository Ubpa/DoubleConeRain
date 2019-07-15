Shader "DoubleConeRain/OneLayerRain"
{
    Properties
    {
		[NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}

		_Intensity ("Intensity", Vector) = (1,0.5,0.25,0.125)
		_IntensityFactor("Intensity Factor", Range(0,1)) = 0.1
		
		_ST0("ST 0", Vector) = (1,1,0,0)
		_ST1("ST 1", Vector) = (1,1,0,0)
		_ST2("ST 2", Vector) = (1,1,0,0)
		_ST3("ST 3", Vector) = (1,1,0,0)

		_SceneTopDepth("Scene Top Depth", 2D) = "black" {}
    }
    SubShader
    {
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        LOD 100

        Pass
        {
			ZWrite Off ZTest On
			Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
				float4 color : COLOR;
            };

            struct v2f
            {
				float4 uv01 : TEXCOORD0;
				float4 uv23 : TEXCOORD1;
				float4 color : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
			uniform float4 _ST0;
			uniform float4 _ST1;
			uniform float4 _ST2;
			uniform float4 _ST3;
			sampler2D _CameraDepthTexture;
			sampler2D _SceneTopDepth;
			uniform float4x4 _mainCamClip2depthCamClip;

			float4 _Intensity;
			float _IntensityFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv01.xy = v.uv *_ST0.xy + _ST0.zw;
				o.uv01.zw = v.uv *_ST1.xy + _ST1.zw;
				o.uv23.xy = v.uv *_ST2.xy + _ST2.zw;
				o.uv23.zw = v.uv *_ST3.xy + _ST3.zw;

				o.color = v.color;

				o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

			fixed VisibilityFromTop(fixed2 screenPos, fixed depth) {
				float z = (1 + UNITY_NEAR_CLIP_VALUE) * depth - UNITY_NEAR_CLIP_VALUE;
				float4 depthCamClipPos = mul(_mainCamClip2depthCamClip, float4(2 * screenPos - 1, z, 1));
				float remapZ = depthCamClipPos.z / depthCamClipPos.w;
				float remapDepth = (remapZ + UNITY_NEAR_CLIP_VALUE) / (1 + UNITY_NEAR_CLIP_VALUE);
				fixed2 uv = (depthCamClipPos.xy / depthCamClipPos.w + 1) / 2;
				float topDepth = DecodeFloatRGBA(tex2D(_SceneTopDepth, uv));
				return step(remapDepth, topDepth);
			}

			fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 val0 = tex2D(_MainTex, i.uv01.xy);
				fixed4 val1 = tex2D(_MainTex, i.uv01.zw);
				fixed4 val2 = tex2D(_MainTex, i.uv23.xy);
				fixed4 val3 = tex2D(_MainTex, i.uv23.zw);

				fixed2 screenPos = i.screenPos.xy / i.screenPos.w;

				// depth 0 近 1 远
				float screenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
#if defined(UNITY_REVERSED_Z)
				screenDepth = 1.0 - screenDepth;
#endif

				// TODO
				// 按远近平面均分四层

				float part0 = 1.0;
				float part1 = 2.0;
				float part2 = 3.0;
				float part3 = 4.0;
				float sumPart = part0 + part1 + part2 + part3;
				float size0 = part0 / sumPart;
				float size1 = part1 / sumPart;
				float size2 = part2 / sumPart;
				float size3 = part3 / sumPart;
				float size01 = size0 + size1;
				float size012 = size01 + size2;

				fixed depth0 = 0.000 + val0.a * size0;
				fixed depth1 = size0 + val1.a * size1;
				fixed depth2 = size01 + val2.a * size2;
				fixed depth3 = size012 + val3.a * size3;

				fixed3 sumCol = fixed3(0,0,0);

				if (depth0 < screenDepth)
					sumCol += val0.rgb * _Intensity.x * VisibilityFromTop(screenPos, depth0);

				if (depth1 < screenDepth)
					sumCol += val1.rgb * _Intensity.y * VisibilityFromTop(screenPos, depth1);

				if (depth2 < screenDepth)
					sumCol += val2.rgb * _Intensity.z * VisibilityFromTop(screenPos, depth2);

				if (depth3 < screenDepth)
					sumCol += val3.rgb * _Intensity.w * VisibilityFromTop(screenPos, depth3);
				
				sumCol *= _IntensityFactor;

				return fixed4(i.color.a * i.color.rgb * sumCol, 1);
            }
            ENDCG
        }
    }
}
