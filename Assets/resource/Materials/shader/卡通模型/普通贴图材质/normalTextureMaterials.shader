Shader "Unlit/normalTextureMaterials"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"// 包含光照计算函数

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                fixed3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Diffuse;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;
                o.worldPos = UnityObjectToWorldDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 环境光源
                fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 纹理 采样
                fixed4 albedo = tex2D(_MainTex, i.uv);

                // 漫反射
                fixed3 worldLightDir = UnityObjectToWorldDir(i.worldPos); // 世界光源方向
                float difLight = dot(worldLightDir, i.worldNormal) * 0.5 + 0.5;// 光源方向与法线 点积

                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * difLight; 


                return float4 (ambient + diffuse, 1);
            }
            ENDCG
        }
    }
}
