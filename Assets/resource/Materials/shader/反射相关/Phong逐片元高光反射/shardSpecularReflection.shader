Shader "Unlit/shardSpecularReflection"
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
                float4 vertex : SV_POSITION;// 顶点
                fixed3 worldNormal : TEXCOORD0;// 法线
                float3 worldPosition : TEXCOORD1;// 世界顶点位置
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                o.worldNormal = worldNormal;
                // o.worldPosition = UnityObjectToWorldDir(v.vertex);// 顶点位置 （世界 空间）错误
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 漫反射
                // 光源方向
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);// _WorldSpaceLightPos0 世界光源方向; 归一化
                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPosition.xyz);


                fixed3 worldNormal = normalize(i.worldNormal);// 归一化

                // fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldLightDir, i.worldNormal));


                // 高光反射
                fixed3 reflectDir = normalize(reflect(-worldLightDir, i.worldNormal));

                // 视角方向1
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                // // 视角方向2 替换 1
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));

                // 高光颜色
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);



                fixed3 color = diffuse + ambient + specular;
                return fixed4 (color, 1);
            }
            ENDCG
        }
    }
}


