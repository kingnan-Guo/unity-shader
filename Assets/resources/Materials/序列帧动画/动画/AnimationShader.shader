Shader "Unlit/AnimationShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 贴图的 行列 个数
        _HorAmount ("Horizontal Amount", float) = 10
        _VerAmount ("Vertical Amount", float) = 10
        _Speed ("Speed", Range(1, 100)) = 1
    }

    SubShader
    {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProjector"="True"// 忽略阴影
        }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha



            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float _HorAmount;
            float _VerAmount;
            float _Speed;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float time = floor(_Time.y * _Speed);   // floor 取整
                float row = floor(time / _HorAmount);   // 获取在哪一行
                float column = time - row * _HorAmount; // 获取在哪一列

                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorAmount;
                uv.y /= _VerAmount;
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}
// 序列帧动画的 原理 是 将贴图 切割 每一帧 换一个 贴图