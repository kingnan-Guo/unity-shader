Shader "Unlit/afterDeferredRenderSencondPassHDR"
{
    Properties
    {
    }
    SubShader
    {


        Pass
        {
            ZWrite Off// 关闭深度写入
            // Blend One One//混合 ： 计算光照 ： 叠加
            Blend [_SrcBlend] [_DstBlend]//混合 ： 计算光照 ： 叠加; 由 外部传入


            CGPROGRAM
            #pragma target 3.0 // opengl 3.0 及以上
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_lightpass // 宏定义 让光照正确计算 提供相应的 关键字  和 shader  变种
            #pragma exclude_renderers_norm // 排除不支持 MRT  渲染 的 硬件

            // 宏定义 专门 处理 HDR; 高动态 ； 精度更高
            #pragma multi_compile __ UNITY_HDR_ON
         



            #include "UnityCG.cginc"
            #include "UnityDeferredLibrary.cginc"
            #include "UnityGBuffer.cginc"
            // #include "AutoLight.cginc" 不能使用 用于计算 光照 衰减 ，因为 内部定义 的 值 与 UnityDeferredLibrary重复


            // 当 使用 UnityGBuffer 后 可以 声明  _Cambertex 变量
            sampler2D _CameraGBufferTexture0;
            sampler2D _CameraGBufferTexture1;
            sampler2D _CameraGBufferTexture2;
            sampler2D _CameraGBufferTexture3;




            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;// 射线
            
            };


            unity_v2f_deferred vert (appdata i)
            {
                unity_v2f_deferred o;
                o.pos = UnityObjectToClipPos(i.vertex);
                // 传入 裁剪空间 的 position ，计算出  float4 的 值 ，是 视口坐标系的 坐标， 在下一步 片元 着色器 xy 分量 除以  w 分量 的齐次坐标，才会 是真正像素 具体的值； （0~1）
                o.uv = ComputeScreenPos(o.pos);
                // 要在 世界空间 进行 光照计算，要把 当前 采样的 这张图的信息 采样出来，需要把当前的 点 转换到 世界空间，
                // 要把像素 上的 点 转换到 齐次裁剪空间，再从 齐次裁剪空间  到 裁剪空间 ，
                // 然后 使用 cameraToWorld 转换到 世界空间；需要知道 当前这个点 在摄像机 里 （齐次裁剪空间） 的位置， 
                // 计算 点在 齐次裁剪空间 位置  是 计算 点 到近平面 或者到 远平面 的 一个 向量；
                // 目的是 计算 向量 长度和方向 这里 是 计算 方向，
                // 然后 在 片元 着色器 根据 投影的值 计算  长度，根据向量再把位置计算出来

                // UnityObjectToViewPos(i.vertex) 视角坐标系的位置， 延Z轴翻转 
                o.ray = UnityObjectToViewPos(i.vertex) * float3(-1, -1, 1);
                // 当处理 四边形 直射光 时 ，o.ray 时 法线 方向； _LightAsQuad 当在处理 四边形时，也就是直射光线返回1， 否则返回 0

                o.ray = lerp(o.ray, i.normal, _LightAsQuad);
                return o;
            }


            #ifdef UNITY_HDR_ON
            half4
            #else
            fixed4
            #endif
            // 整个过程的 目的 是  要将 当前像素 的 位置 转换到 世界空间，然后 根据世界空间的位置，计算 光照
            frag (unity_v2f_deferred i) : SV_Target
            {
                // 计算 真正的 uv
                float2 uv = i.uv.xy / i.uv.w;
                // 进行采样
                // 计算深度 通过 深度 和 方向 重新 计算 世界坐标
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uv);// _CameraDepthTexture 自动返回的值
                depth = Linear01Depth(depth);// 深度线性化; 获取到线性的 深度值 （0~1）
                // 计算 完深度 就可以根据 之间的ray 的方向 ，计算出 长度 然后 计算出世界坐标；


                //ray 只能表示方向 ， 长度不一定；
                /// _ProjectionParams.z 代表的时 远平面， 因为 xyz 是等比列 ，
                // 所以 _ProjectionParams.z/i.ray 就是 rayToFarPlane 向量 和 i.ray 向量 的比值
                float3 rayToFarPlane = i.ray * (_ProjectionParams.z / i.ray.z);

                // 视角的 位置
                float4 viewPos = float4(rayToFarPlane * depth, 1);

                float3 worldPos = mul(unity_CameraToWorld, viewPos).xyz;

                // 阴影 消失的位置 
                float fadeDist = UnityComputeShadowFadeDistance(worldPos, viewPos.z);


                // 接下来 对不同 的 光进行  衰减 计算； 包括 阴影计算， 计算出 衰减的值 然后 计算最终的 颜色 













                half3 lightDir;
                float atten;
                float3 toLight;
                float4 uvCookie;
                // 计算 光照 衰减
                // cookie 是一个 2d 纹理，也就是 光照 的贴图， 照出 的光 是有 纹理的
                #if defined(SPOT) // 区域光  没有 SPOT_COOKIE
                    toLight = _LightPos.xyz - worldPos;
                    // 计算 光源 方向
                    lightDir = normalize(_LightPos.xyz - worldPos);
                    // 获取 cookie 的uv ; 没有齐次裁剪
                    uvCookie = mul(unity_worldToLight, float4(worldPos, 1));
                    atten = tex2Dbias(_LightTexture0, float4(uvCookie.xy/uvCookie.w, 0, -8)).w;

                    // atten 的方向判断
                    atten *= uvCookie < 0;

                    // 使用了 cookie 的cookie 采样
                    atten *= tex2D(_LightTextureB0, dot(toLight, toLight) * _LightPos.w).r;

                    // 阴影
                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

                #elif defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)// 定义了 方向 光 或者 方向光的  cookie
                    lightDir = -_LightDir.xyz;

                    atten = 1.0;

                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);
                    

                    // 如果 定义了 方向光  的cookie
                    #if defined(DIRECTIONAL_COOKIE)
                        uvCookie = mul(unity_worldToLight, float4(worldPos, 1));
                        // 因为 不是 透视 所以 uvCookie.xy  不要需要 除以 uvCookie.w
                        atten *= tex2Dbias(_LightTexture0, float4(uvCookie.xy, 0, -8)).w;
                    #endif


                #elif defined(POINT) || defined(POINT_COOKIE)// 定义了 点光 或者 点光的 cookie


                    toLight = _LightPos.xyz - worldPos;
                    // 计算 光源 方向
                    lightDir = normalize(_LightPos.xyz - worldPos);

                    atten = tex2D(_LightTextureB0, dot(toLight, toLight) * _LightPos.w).r;

                    atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);


                    // 如果 定义了 方向光  的cookie
                    #if defined(POINT_COOKIE)
                        uvCookie = mul(unity_worldToLight, float4(worldPos, 1));
                        // texCUBEbias 
                        atten *= texCUBEbias(_LightTexture0, float4(uvCookie.xyz, -8)).w;
                    #endif




                #else// 其他 光源
                    lightDir = 0;
                    // 衰减
                    atten = 0;
                #endif




                // ---------- unity  提供 的光照 衰减 的 函数 UnityDeferredCalculateLightParams 要配合  unity_v2f_deferred
                // **************** 这个 可以替换 上面 的所有 代码 *************8
                // float2 uv;
                // half3 lightDir;
                // float atten;
                // float fadeDist;
                // float3 worldPos;
                // UnityDeferredCalculateLightParams(
                //     i, worldPos, uv, lightDir, atten, fadeDist
                // );

                // -----------end-----------









                // 25 延迟 渲染 光照 计算
                fixed3 lightColor = _LightColor.rgb * atten;
                // 反 采样 
                half4 gbuffer0 = tex2D(_CameraGBufferTexture0, uv);
                half4 gbuffer1 = tex2D(_CameraGBufferTexture1, uv);
                half4 gbuffer2 = tex2D(_CameraGBufferTexture2, uv);


                //2D
                half3 diffuseColor = gbuffer0.rgb;

                half3 specularColor = gbuffer1.rgb;
                float gloss = gbuffer1.a * 256;


                float3 worldNormal = normalize(gbuffer2.xyz * 2 - 1);

                fixed3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);

                fixed3 halfDir = normalize(viewDir + lightDir);

                half3 diffuse = lightColor * diffuseColor * max(dot(halfDir, worldNormal), 0);

                half3 specular = lightColor * specularColor * pow(max(dot(halfDir, worldNormal), 0), gloss);

                // fixed3 ambient = lightColor * diffuseColor * 0.1;

                half4 color = half4(specular + diffuse, 1)  ;


                #ifdef UNITY_HDR_ON
                return color;
                #else
                return exp2(-color);// 转码
                #endif

                // return color;
            


            }
            ENDCG
        }


        // 26 节 转码 pass 通道
        // 主要是 对 LDR 转码
        // LDR 是 Blend DstColor Zero
        // HDR 是 Blend SrcAlpha OneMinusSrcAlpha

        pass{

            ZTest Always
            Cull Off
            ZWrite Off



            Stencil{
                ref[_StencilNonBackground]
                readMask[_StencilNonBackground]

                compback equal
                compfront equal
            }

            CGPROGRAM
            #pragma target 3.0 // opengl 3.0 及以上
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_lightpass // 宏定义 让光照正确计算 提供相应的 关键字  和 shader  变种
            #pragma exclude_renderers_normt // 排除不支持 MRT  渲染 的 硬件


            #include "UnityCG.cginc"

            sampler2D _LightBuffer;

            struct v2f{
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 texcood: TEXCOORD1;
                
            };

            v2f vert(float4 vertex:POSITION, float2 texcood: TEXCOORD0){
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                o.texcood = texcood.xy;

                #ifdef UNITY_SINGLE_PASS_STEREO
                    o.texcood = TransformStereoScreenSpaceTex(o.texcood);

                #endif
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
  
                return -log2(tex2D(_LightBuffer, i.texcood));
            }



            ENDCG
        }
    }
}
// 延时渲染 后处理



//  现在  第二个 pass  使用的 是  项目设置 -> 图形 -> 内置着色器设置  ->  延时 -> 替换 着色器