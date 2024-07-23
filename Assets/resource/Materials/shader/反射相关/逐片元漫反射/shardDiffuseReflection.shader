Shader "Unlit/shardDiffuseReflection"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"// 包含光照计算函数

            fixed4 _Diffuse;

            // struct appdata
            // {
            //     float4 vertex : POSITION;
            //     float2 uv : TEXCOORD0;
            //     float3 normal: NORMAL;
            // };

            struct v2f
            {
                float4 vertex : SV_POSITION;// 顶点
                fixed3 worldNormal : TEXCOORD0;// 法线
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                o.worldNormal = worldNormal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                // 光源方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);// _WorldSpaceLightPos0 世界光源方向; 归一化

                fixed3 worldNormal = normalize(i.worldNormal);// 归一化
                // 漫反射
                // fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldLightDir, i.worldNormal));
                fixed3 color = diffuse + ambient;
                return fixed4 (color, 1);
                // return fixed4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
}

