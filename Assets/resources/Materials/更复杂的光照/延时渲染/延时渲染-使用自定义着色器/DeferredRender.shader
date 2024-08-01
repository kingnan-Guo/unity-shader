Shader "Unlit/DeferredRender"
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
                "LightMode"="Deferred"
            }
            CGPROGRAM
            #pragma target 3.0 // opengl 3.0 及以上
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers_norm // 排除不支持 MRT  渲染 的 硬件

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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            struct DefferredOutput{
                float4 gBuffer0 : SV_Target0; // 颜色   RT0 格式 是 ARGB32 每个通道8 位，RGB用于储存 漫反射 颜色，A通道 储存遮挡
                float4 gBuffer1 : SV_Target1; // 颜色   RT1 格式 是 ARGB32 每个通道8 位，RGB用于储存 高光反射 颜色，A通道 储存 高光反射的指数 部分
                float4 gBuffer2 : SV_Target2; //法线    RT2 格式 是 ARGB2101010 每个通道 16 位，RGB用于储存 世界空间法线，A通道 没有被使用 （为什么 是 16 位 ，明明是 10 位）
                float4 gBuffer3 : SV_Target3; //        RT3 格式 是 ARGB2101010 / ARGBHalf 每个通道 16 位，（高动态光照渲染、低动态光照渲染）用于储存自发光 + lightmap + 反射探针深度换成和模板缓冲；当在第二个Pass 中计算光照时，默认情况下 尽可以使用 Unity 内置的 standard 光照
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            // fixed4 frag (v2f i) : SV_Target
            // {
            //     // sample the texture
            //     fixed4 col = tex2D(_MainTex, i.uv);
            //     return col;
            // }

            DefferredOutput frag (v2f i)
            {
                DefferredOutput o;
                fixed3 color = tex2D(_MainTex, i.uv).rgb * _Diffuse.rgb;
                o.gBuffer0.rgb = color;
                o.gBuffer0.a = 1;// 遮罩纹理 使用  unity 默认 的第二个pass 这里 传 1，（遮罩）； 但是使用自己写的遮罩 那么这里的值 时自定义 
                o.gBuffer1.rgb = _Specular.rgb;
                o.gBuffer1.a = ( _Gloss / 256.0);

                // 由于 法线 有 负值  所以  法线 * 0.5 + 0.5  这样  法线 的 范围 是 0 - 1
                o.gBuffer2 = float4(normalize(i.worldNormal) * 0.5 + 0.5, 1);
                
                o.gBuffer3 = float4(color, 1); //当前这里 只存 模板缓冲 ，模板 缓冲 只有 深度信息，没有颜色信息，所以这里存颜色信息，方便后处理使用 ？？？？？
                return o;
            
            }


            ENDCG
        }
    }
}


// 延迟渲染
// 分为两个 pass
// 1. 生成 G-buffer
// 2. 使用 G-buffer 渲染场景


// 反射探针，顾名思义，就是为反射效果获取外界信息的探测器。 https://zhuanlan.zhihu.com/p/438022045
// 在场景中未使用反射探针时，场景中具有反射(包括镜面反射Specular和金属反射Metallic)的物体会使用天空贴图(包括天空面 Sky Plane / 天空盒 Sky Box / 天空球 Sky Dome)的信息来制作反射效果。

// 模板缓存(stencil buffer)
// 模板缓存通常作为用来作为每个像素的掩码来觉得是否丢弃该像素的数据。
//  模板缓冲区通常是每像素8位整数。该值可以被写入、递增或递减。随后的绘制调用可以根据该值进行测试，以确定在运行像素着色器之前是否应该丢弃像素。



// 现在  第二个 pass  使用的 是  项目设置 -> 图形 -> 内置着色器设置  ->  延时 -> 内置着色器