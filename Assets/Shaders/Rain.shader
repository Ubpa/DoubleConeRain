Shader "DoubleConeRain/Rain"
{
    Properties
    {
		[NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}

		_Intensity ("Intensity", Vector) = (1,0.5,0.25,0.125)
		_IntensityFactor("Intensity Factor", Range(0,1)) = 0.1
		
		_RainST0("ST 0", Vector) = (1,1,0,0)
		_RainST1("ST 1", Vector) = (1,1,0,0)
		_RainST2("ST 2", Vector) = (1,1,0,0)
		_RainST3("ST 3", Vector) = (1,1,0,0)

		_DepthT("Depth T", Vector) = (0,0,0,0)
		_DepthS("Depth S", Vector) = (0,0,0,0)

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
			uniform float4 _RainST0;
			uniform float4 _RainST1;
			uniform float4 _RainST2;
			uniform float4 _RainST3;
			uniform float4 _DepthT;
			uniform float4 _DepthS;
			sampler2D _CameraDepthTexture;
			sampler2D _SceneTopDepth;
			uniform float4x4 _mainCamClip2depthCamClip;

			float4 _Intensity;
			float _IntensityFactor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv01.xy = v.uv *_RainST0.xy + _RainST0.zw;
				o.uv01.zw = v.uv *_RainST1.xy + _RainST1.zw;
				o.uv23.xy = v.uv *_RainST2.xy + _RainST2.zw;
				o.uv23.zw = v.uv *_RainST3.xy + _RainST3.zw;

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

				float eyeDepth0 = val0.a * _DepthS.x + _DepthT.x;
				float eyeDepth1 = val1.a * _DepthS.y + _DepthT.y;
				float eyeDepth2 = val2.a * _DepthS.z + _DepthT.z;
				float eyeDepth3 = val3.a * _DepthS.w + _DepthT.w;

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
