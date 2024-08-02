Shader "Unlit/fresnel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 菲涅尔系数
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 1.0
        _CubeMap ("CubeMap", CUBE) = "skyBox"{} 
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
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
                float3 WorldRefl : TEXCOORD4;
            };

            sampler2D_float _MainTex;// sampler2D_float 比 sampler2D  精度更高
            float4 _MainTex_ST;
            float _FresnelScale;
            samplerCUBE _CubeMap;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                // 计算反射 ； 用入射光线 和 法线 计算反射; 得到反射方向
                o.WorldRefl = reflect(-o.worldViewDir, o.worldNormal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {






                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldViewDir = normalize(i.worldViewDir);
                fixed3 worldPos = i.worldPos;
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));


                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 漫发射
                fixed3 diffuse = _LightColor0.rgb * tex2D(_MainTex, i.uv).rgb * saturate(dot(worldNormal, worldLightDir));

                // 高光
                // fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(reflect(-worldViewDir, worldNormal), worldLightDir)), _Gloss);

                // 反射 采样 cubeMap 
                fixed3 refection = texCUBE(_CubeMap, i.WorldRefl).rgb;


                // 菲尼尔 反射 : _FresnelScale 菲尼尔系数 ；  菲尼尔系数 + (1 - 菲尼尔系数) * (1 - dot(worldViewDir, worldNormal)) ^5
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);



                // 模型颜色， 环境光  + （diffuse 与 反射颜色的融合 ） saturate(fresnel)  菲尼尔 反射 系数
                fixed3 color = ambient + lerp(diffuse, refection, saturate(fresnel));

                // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, color);
                return float4(color, 1.0);

            }
            ENDCG
        }
    }
}

// fresnel 菲涅尔反射
// 代表 反射 和 折射的 关系
//  菲涅尔反射 近似 公式

// 在 坐 水面  效果 的 时候  会用到  菲涅尔反射