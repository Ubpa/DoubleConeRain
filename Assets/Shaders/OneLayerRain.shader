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

			void frag (v2f i, out fixed4 color : COLOR, out float depth : DEPTH)
			//void frag(v2f i, out fixed4 color : COLOR)
            {
                // sample the texture
                fixed4 val0 = tex2D(_MainTex, i.uv01.xy);
				fixed4 val1 = tex2D(_MainTex, i.uv01.zw);
				fixed4 val2 = tex2D(_MainTex, i.uv23.xy);
				fixed4 val3 = tex2D(_MainTex, i.uv23.zw);

				// depth 1 近 0 远
				float screenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);

				fixed depth0 = 1 - (0.000 + val0.a * 0.067);
				fixed depth1 = 1 - (0.067 + val1.a * 0.133);
				fixed depth2 = 1 - (0.200 + val2.a * 0.267);
				fixed depth3 = 1 - (0.467 + val3.a * 0.533);

				fixed3 sumCol = fixed3(0,0,0);

				if (depth0 > screenDepth)
					sumCol += val0.rgb * _Intensity.x;

				if (depth1 > screenDepth)
					sumCol += val1.rgb * _Intensity.y;

				if (depth2 > screenDepth)
					sumCol += val2.rgb * _Intensity.z;

				if (depth3 > screenDepth)
					sumCol += val3.rgb * _Intensity.w;
				
				sumCol *= _IntensityFactor;

				color = fixed4(i.color.a * i.color.rgb * sumCol, 1);
				//color = fixed4(screenDepth, 0, 0, 1);
				depth = max(max(max(val0.a, val1.a), val2.a), val3.a);
				//depth = 1;
            }
            ENDCG
        }
    }
}
