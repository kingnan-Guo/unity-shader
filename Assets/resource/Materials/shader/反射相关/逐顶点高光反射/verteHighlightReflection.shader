Shader "Unlit/verteSpecularReflection"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)// 高光 
        _Gloss("Gloss", Range(1, 256)) = 1
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
            fixed4 _Specular;
            float _Gloss;

            struct v2f
            {
                fixed3 color: Color;
                float4 vertex : SV_POSITION;// 顶点
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                // 光源方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);// _WorldSpaceLightPos0 世界光源方向; 归一化
                // 光源颜色
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));// 漫反射计算
                
                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));// 反射方向
                
                // 视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - UnityObjectToWorldDir(v.vertex));
                // 高光
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(reflectDir, viewDir)), _Gloss);

                o.color = diffuse + ambient + specular;// 颜色 值 等于 漫反射 加 环境光 +  高光

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4 (i.color, 1);
            }
            ENDCG
        }
    }
}
