﻿Shader "DoubleConeRain/Rain"
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
			ZWrite Off ZTest Off
			Blend One One
			//Blend One Zero

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

			fixed VisibilityFromTop(fixed2 screenPos, float eyeDepth) {
				float screenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenPos);
				float depth = (1.0 / eyeDepth - _ZBufferParams.w) / _ZBufferParams.z;

#if defined(UNITY_REVERSED_Z)
				screenDepth = 1.0 - screenDepth;
				depth = 1.0 - depth;
#endif
				//return depth;

				fixed visibility0 = step(depth, screenDepth);
				//return visibility0;

				float z = (1 + UNITY_NEAR_CLIP_VALUE) * depth - UNITY_NEAR_CLIP_VALUE;
				float4 depthCamClipPos = mul(_mainCamClip2depthCamClip, float4(2 * screenPos - 1, z, 1));
				float remapZ = depthCamClipPos.z / depthCamClipPos.w;
				float remapDepth = (remapZ + UNITY_NEAR_CLIP_VALUE) / (1 + UNITY_NEAR_CLIP_VALUE);
				fixed2 uv = (depthCamClipPos.xy / depthCamClipPos.w + 1) / 2;
				float topDepth = DecodeFloatRGBA(tex2D(_SceneTopDepth, uv));

				fixed visibility1 = step(remapDepth, topDepth);

				return visibility0 * visibility1;
			}

			fixed4 frag (v2f i) : SV_Target
            {
				// sample the texture
				fixed4 val0 = tex2D(_MainTex, i.uv01.xy);
				fixed4 val1 = tex2D(_MainTex, i.uv01.zw);
				fixed4 val2 = tex2D(_MainTex, i.uv23.xy);
				fixed4 val3 = tex2D(_MainTex, i.uv23.zw);

				fixed2 screenPos = i.screenPos.xy / i.screenPos.w;

				// TODO
				// 合理划分区域
				float delta = _ProjectionParams.z - _ProjectionParams.y; // far - near
				float qtrDelta = delta / 4.0;
				float eyeDepth0 = _ProjectionParams.y + (0.0 + val0.a) * qtrDelta;
				float eyeDepth1 = _ProjectionParams.y + (1.0 + val1.a) * qtrDelta;
				float eyeDepth2 = _ProjectionParams.y + (2.0 + val2.a) * qtrDelta;
				float eyeDepth3 = _ProjectionParams.y + (3.0 + val3.a) * qtrDelta;

				fixed3 sumCol = fixed3(0,0,0);

				sumCol += val0.rgb * _Intensity.x * VisibilityFromTop(screenPos, eyeDepth0);
				sumCol += val1.rgb * _Intensity.y * VisibilityFromTop(screenPos, eyeDepth1);
				sumCol += val2.rgb * _Intensity.z * VisibilityFromTop(screenPos, eyeDepth2);
				sumCol += val3.rgb * _Intensity.w * VisibilityFromTop(screenPos, eyeDepth3);
				
				sumCol *= _IntensityFactor;

				return fixed4(i.color.a * i.color.rgb * sumCol, 1);
				//fixed rst = VisibilityFromTop(screenPos, eyeDepth0);
				//return fixed4(rst, rst, rst, 1);
            }
            ENDCG
        }
    }
}