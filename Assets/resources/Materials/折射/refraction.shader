Shader "Unlit/refraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Diffuse", Color)  =  (1,1,1,1) // 物体颜色
        _CubeMap ("CubeMap", CUBE) = "skyBox"{}
        _RefractionColor ("RefractionColor", Color) = (1, 1, 1, 1)
        _RefractionAmount ("RefractionAmount", Range(0, 1)) = 1//强度
        _RefractionRotio ("RefractionRotio", Range(0, 1)) = 0.5// 折射率
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            // #include "AutoLight.cgnic"
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
                float3 WorldRefr : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _RefractionColor;
            samplerCUBE _CubeMap;
            float _RefractionAmount;
            fixed _RefractionRotio;



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                // 计算折射 ； 用入射光线方向  和 法线 计算反射  _RefractionRotio 折射率 ; 得到 折射方向
                o.WorldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractionRotio);
                

                UNITY_TRANSFER_FOG(o,o.vertex);
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

                // 反射 采样 cubeMap 乘以 折射 颜色
                fixed3 refection = texCUBE(_CubeMap, i.WorldRefr).rgb * _RefractionColor;

                // 模型颜色， 环境光  + （diffuse 与 反射颜色的融合 ） _RefractionAmount是折射强度
                fixed3 color = ambient + lerp(diffuse, refection, _RefractionAmount);

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


// 折射 计算 
// n1 * sin(i1) = n2 * sin(i2)
// i1 = 入射角
// i2 = 折射角
// n1 = 1.0 // 折射率
// n2 = 1.5 // 折射率
// sin(i2) = sin(i1) / n2
// i2 = asin(sin(i1) / n2)
// i2 = asin(1.0 / 1.5)
// i2 = asin(0.6666)
// i2 = 41.8°
// i2 = 41.8°