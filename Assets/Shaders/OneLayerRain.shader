Shader "DoubleConeRain/OneLayerRain"
{
    Properties
    {
		[NoScaleOffset]
        _MainTex ("Texture", 2D) = "white" {}
		_Intensity ("Intensity", Range(0,1)) = 1.0
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
			ZWrite Off
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
			uniform float4 _ST0;
			uniform float4 _ST1;
			uniform float4 _ST2;
			uniform float4 _ST3;

			float _Intensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv01.xy = v.uv *_ST0.xy + _ST0.zw;
				o.uv01.zw = v.uv *_ST1.xy + _ST1.zw;
				o.uv23.xy = v.uv *_ST2.xy + _ST2.zw;
				o.uv23.zw = v.uv *_ST3.xy + _ST3.zw;

				o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col0 = tex2D(_MainTex, i.uv01.xy);
				fixed4 col1 = tex2D(_MainTex, i.uv01.zw);
				fixed4 col2 = tex2D(_MainTex, i.uv23.xy);
				fixed4 col3 = tex2D(_MainTex, i.uv23.zw);
				fixed4 col = col0 + col1 + col2 + col3;
				col *= i.color;
                return fixed4(col.xyz * col.a * _Intensity, 1);
            }
            ENDCG
        }
    }
}
