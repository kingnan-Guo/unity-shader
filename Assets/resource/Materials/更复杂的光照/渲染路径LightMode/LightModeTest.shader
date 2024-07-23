Shader "Unlit/LightModeTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Diffuse", Color)  =  (1,1,1,1) // 物体颜色
        _Specular ("Specular", Color) = (1,1,1,1) // 高光
        _Gloss ("Gloss", Range(0, 256)) = 20 // 高光强度 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
                "LightMode" = "ForwardBase" // 控制了当前 的渲染路径； 当前这个物体 是 前向渲染 的情况下，下面的代码才会 在前向渲染执行，如果 设置其他的不会去执行； 但是会 兼容 延迟渲染，在 延迟 渲染的 渲染路径下 光照不会被执行
                // "LightMode" = "Deferred" // 控制了当前 的渲染路径； 当前这个物体 是 延迟渲染 的情况下，下面的代码才会 在延迟渲染执行，如果 设置其他的不会去执行
                // "LightMode" = "Always" // 所有的 渲染路径 都会被渲染
            }


            CGPROGRAM
            #pragma multi_compile_fwdbase // 前向渲染 基础光照 宏定义，可以为相应类型的 pass 生成所需要的 shander 变种，这些变种 会处理 不同条件下的渲染逻辑，例如书否使用 lightmap，当前使用哪种官员类型 等
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog // 雾效 宏定义

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 vertextLight : TEXCOORD2;// 顶点 光照 值
            };



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;


                // 在 LightMap 关闭情况下 才会进行 顶点 和 球谐函数 光照计算； lightmap 烘焙后 的光照贴图
                #ifdef LIGHTMAP_OFF
                //球谐函数 ShadeSH9 -> UnityCG.cginc
                float3 shLight = ShadeSH9(float4(v.normal, 1.0));// shLight 球谐函数 计算具体光源的值
                o.vertextLight = shLight;

                    // 接下来 是 逐顶点 计算
                    #ifdef VERTEXLIGHT_ON// 如果 顶点光源是 开的 情况下
                    float3 vertexLight = Shade4PointLights(

                        // 第一盏光的位置
                        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        // 第 n 盏光的颜色, 最多 四盏
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        // lightAttenSq 光照的 衰弱
                        unity_4LightAtten0,
                        // 
                        o.worldPos, o.worldNormal

                    ); // 逐顶点 光源 计算

                    o.vertextLight += vertexLight;

                    #endif

                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 计算 wordNormal
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldPos = i.worldPos;

                // 世界 
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 漫反射
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldNormal, worldLightDir));

                // 视角方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos.xyz);

                // 半角 
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光 ; _LightColor0.rgb 方向 光 应该就是 平行光
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + (diffuse + specular) + i.vertextLight, 1.0);
            }
            ENDCG
        }
    }
}
