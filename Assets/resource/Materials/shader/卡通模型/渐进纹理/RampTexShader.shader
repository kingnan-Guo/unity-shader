Shader "Unlit/simpleColorShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse ("Color", Color) = (1, 1, 1, 1)
        _OutLine("OutLine", Range(0, 2)) = 0.5 // 描边宽度
        _OutLineColor("OutLineColor", Color) = (0, 0, 0, 1) // 描边 颜色

        _Steps("steps", Range(0, 20)) = 0.5 // 离散化参数
        _ToonEffect("ToonEffect", Range(0, 1)) = 0.5// 卡通化 参数


        _RampTex("RampTex", 2D) = "white" {} // 渐进 纹理
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass{
            Name "OutLine"// 外部使用此 需要大写 此名字
            Cull Front // 绘制哪里 ； 剔除正面 ，如果 是 Cull back 那么是 剔除背面 只绘制正面


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _OutLine;
            fixed4 _OutLineColor;
            

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata_base v)
            {
                v2f o;
                // 法线外移
                o.vertex= UnityObjectToClipPos(v.vertex); //

                // float3 normal = UnityObjectToWorldNormal(v.normal);
                //  转到视角 坐标 下 z 值 就是 纯粹的 深度
                float3 normal_view = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));// 2、世界法线转换  视角 法线; UNITY_MATERX_IT_MV 物体坐标 到 世界坐标
                // 世界 视角空间 转换到 裁剪空间
                float2 viewNormal = normalize(TransformViewToProjection(normal_view.xy));//
                
                o.vertex.xy += viewNormal * _OutLine;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 环境光源
                // fixed3 ambient =  UNITY_LIGHTMODEL_AMBIENT.xyz;
                

                return _OutLineColor;
            }



            ENDCG
        }

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
            float _Steps;
            float _ToonEffect;

            sampler2D _RampTex;// 纹理
            float4 _RampTex_ST;// 是 _RampTex 的附属物 ，包含纹理的缩放和偏移


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


                // 渐进贴图采样
                fixed rampColor = tex2D(_RampTex, fixed2(difLight, difLight));

                // 简化颜色 颜色设置在 0～1 之间
                difLight = smoothstep(0, 1, difLight);// 设置 0～ 1 之间'
            
                
                


                //  颜色 离散化
                float toon = floor(difLight * _Steps) /  _Steps;// floor 向下取整； floor(-1.3) = -2.0
                difLight = lerp(difLight, toon, _ToonEffect);//  卡通化 参数 lerp 离散


                // fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb  * difLight;
                
                // rampColor 渐进纹理采样
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb  * rampColor;
                


                return float4 (ambient + diffuse, 1);
            }
            ENDCG
        }
    }
}

// 
