// Shader "Unlit/grabPassShader"
// {
//     Properties
//     {
//         _MainTex ("Texture", 2D) = "white" {}
//         _Diffuse ("Color", Color) = (1,1,1,1)
//         _DumpMap ("DumpMap", 2D) = "white" {}
//         _DumpScale ("DumpScale", Range(0,1)) = 1
//     }

//     SubShader
//     {
//         Tags { "RenderType"="Opaque" }
//         LOD 100

//         Pass
//         {
//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag

//             #include "UnityCG.cginc"
//             #include "Lighting.cginc"


//             struct appdata
//             {
//                 float4 vertex : POSITION;
//                 float2 uv : TEXCOORD0;
//             };

//             struct v2f
//             {
//                 float2 uv : TEXCOORD0;
//                 float4 vertex : SV_POSITION;
//             };

//             sampler2D _MainTex;
//             float4 _MainTex_ST;
//             sampler2D _DumpMap;
//             float _DumpScale;
//             fixed3 _Diffuse;

//             v2f vert (appdata v)
//             {
//                 v2f o;
//                 o.vertex = UnityObjectToClipPos(v.vertex);
//                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                 return o;
//             }

//             fixed4 frag (v2f i) : SV_Target
//             {
//                 fixed4 col = tex2D(_MainTex, i.uv);
//                 fixed4 dump = tex2D(_DumpMap, i.uv);
//                 col.rgb = lerp(col.rgb, dump.rgb, _DumpScale);
//                 return col;
//             }




//             ENDCG
//         }
//     }
// }


Shader "Unlit/grabPassShader"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {} // 纹理
        _BumpMap("Normal Map", 2D) = "bump" {} // 法线贴图
        _BumpScale("BumpScale", Range(0, 10)) = 1 // 法线贴图缩放； 用于控制 凹凸程度

        _SpecularMask("Specular Mask", 2D) = "white" {} // 高光 遮照 纹理
        _SpecularScale("Specular Scale", Range(0, 10)) = 1 // 高光 遮照 纹理缩放； 用于控制 高光 遮照程度

        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)// 高光 
        _Gloss("Gloss", Range(1, 256)) = 1

        _CubeMap ("CubeMap", CUBE) = "skyBox"{}
        // 玻璃 是否清晰的成都
        _Distortion ("Distortion", Range(0, 100)) = 10
        _DistortionScale ("Distortion Scale", Range(0, 1)) = 0.1
        _RefractionAmount ("RefractionAmount", Range(0, 1)) = 1//折射强度
        // _RefractionRotio ("RefractionRotio", Range(0, 1)) = 0.5// 折射率

    }

    SubShader
    {
        Tags {
            "RenderType"="Opaque"
            "Queue"="Transparent+100"
        }
        LOD 100

        // 抓屏 GrabPass
        GrabPass{
            "GrabPass" //  抓屏 是 有 时机的  也是也需要 渲染顺序 所以  上面 的 tags  添加 queue Transparent ; 不透明 物体渲染完成后 才会进行抓屏 通道
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"// 包含光照计算函数

            sampler2D _MainTex;// 纹理
            float4 _MainTex_ST;// 是 _MainTex 的附属物 ，包含纹理的缩放和偏移

            sampler2D _BumpMap;// 法线贴图
            float4 _BumpMap_ST;// 是 _BumpMap 的附属物 ，包含纹理的缩放和偏移
            float _BumpScale;// 法线贴图缩放

            sampler2D _SpecularMask;// 高光 遮照 纹理
            float4 _SpecularMask_ST;
            float _SpecularScale;// 高光 遮照 纹理缩放

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;


            // 声明抓屏采样
            sampler2D GrabPass;
            float4 _GrabPass_ST;
            float4 GrabPass_TexelSize;// 获取到 GrabPass  的大小； 宽高的像素值
            float _RefractionAmount;// 抓屏的透明度

            float _Distortion;// 抓屏的偏移量
            float _DistortionScale;// 抓屏的偏移量缩放

            samplerCUBE _CubeMap;

            

            struct v2f
            {
                float4 vertex : SV_POSITION;// 顶点
                // fixed3 worldNormal : TEXCOORD0;// 法线 不需要了
                fixed3 lightDir : TEXCOORD0;// 光源 方向
                
                // float3 worldPosition : TEXCOORD1;// 世界顶点位置 不需要了
                fixed3 viewDir : TEXCOORD1;// 视角方向

                float4 uv : TEXCOORD2;//TEXCOORD2 语义:获取该模型纹理坐标 ； 用模型的 第三套 纹理坐标填充 TEXCOORD2

                float2 MaskUv : TEXCOORD3;// 法线贴图的UV


                float4 scrPos: TEXCOORD4;// 抓屏纹理坐标
            };

            
            // 顶点着色器 
            // appdata_tan 是自定义的结构体，包含顶点位置、法线、切线、纹理坐标
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                // o.worldNormal = worldNormal; 不需要了
                // o.worldPosition = UnityObjectToWorldDir(v.vertex);// 顶点位置 （世界 空间）
                // o.worldPosition = mul(unity_ObjectToWorld, v.vertex); 不需要了

                // 让 外面的数值 可以影响到 uv
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;// 纹理坐标 ; https://www.lfzxb.top/unity-shader-base-texcoordn/
                // 替换上面
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);// 纹理坐标；也就是俗称的UV，是顶点数据的一部分； uv和有没有贴图没关系哦，uv是网格的属性


                // 法线贴图 ================
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);// 法线贴图 纹理坐标
                o.MaskUv = TRANSFORM_TEX(v.texcoord, _SpecularMask);// 高光 遮照 纹理坐标

                // 光照方向 和 视角方向


                // 使用 TANGENT_SPACE_ROTATION 矩阵，把世界空间的光照方向 转换成 切线空间; 可以替换上面的 1、2; ; 这个是Unity的内置宏，在UnityCG.cginc中被定义 
                TANGENT_SPACE_ROTATION;
                
                // 求切线空间视角及 光源方向 
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;// ObjSpaceLightDir 将光照转换成模型空间； 再乘以 旋转矩阵转到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz; // ObjSpaceViewDir 将视角转换成模型空间； 再乘以 旋转矩阵转到切线空间



                o.scrPos = ComputeGrabScreenPos(o.vertex); // 裁剪坐标  转到  抓屏纹理坐标
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                //法线 =======
                // 切线空间的 光源 方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                // 切线空间的 视角方向
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 法线贴图的采样
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从 _BumpMap 纹理中提取法向信息
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 

 
                // 将 法线 贴图设置成 normal map，不需要要 乘以 2，然后减去 1； 直接使用法线贴图的颜色值即可
                fixed3 tangentNormal = UnpackNormal(packedNormal);// UnpackNormal 解压 法线贴图
                tangentNormal.xy  *=  _BumpScale;

                // 法线 ======= end






                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 纹理图片采样 =========== 
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从_Bump纹理中提取法向信息
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 


                // 漫反射 ==============
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(tangentLightDir, tangentNormal)) * 0.5 + 0.5);






                // 采样 抓屏 贴图 === start

                // 偏移
                float2 offset = tangentNormal.xy * _Distortion * GrabPass_TexelSize; // GrabPass_TexelSize 抓屏纹理的像素大小

                // 对深度 进行 扰动
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                // 当前 已经 把 uv 计算完成了 ？？？？？？  咋计算的

                // 开始 计算 折射； 采样 GrabPass; 要把 深度值 做为齐次 除法  还原深度值
                fixed3 refrCol = tex2D(GrabPass, i.scrPos.xy/ i.scrPos.w).rgb;


                // 反射
                fixed3 reflCol = texCUBE(_CubeMap, reflect(-tangentViewDir, tangentNormal)).rgb * albedo;


                 // 采样 抓屏 贴图 ==== end




                // 融合 ==============
                fixed3 color =  reflCol * (1- _RefractionAmount) + refrCol * _RefractionAmount;

                return fixed4 (color, 1);


                // // 高光反射 ===========
                // // 半角向量
                // // fixed3 halfDir = normalize(worldLightDir + viewDir);// 光源向量 +  视角向量
                // fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
              
                // // 高光颜色
                // fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);

                // // 高光 遮照 ； 要 忽略的 通道 r
                // fixed3 specularMask = tex2D(_SpecularMask, i.MaskUv).r * _SpecularScale;
                // specular *= specularMask;


                // fixed3 color = diffuse + ambient + specular;
                // return fixed4 (color, 1);
            }
            ENDCG
        }
    }
}


// 抓屏
// 有 抓屏 之后  玻璃就有本身的 贴图 和  采样 了

