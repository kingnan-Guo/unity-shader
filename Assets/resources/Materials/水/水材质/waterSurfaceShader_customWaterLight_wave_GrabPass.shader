Shader "Custom/waterSurfaceShader_customWaterLight_wave_GrabPass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        // _Glossiness ("Smoothness", Range(0,1)) = 0.5
        // _Metallic ("Metallic", Range(0,1)) = 0.0
        // 浅水区 颜色值
        _WaterShallowColor ("WaterShallowColor", Color) = (0.2,0.2,0.2,1)
        // 浅水区 深度值
        // _WaterShallowDepth ("WaterShallowDepth", Range(0,1)) = 0.5
        // 深水区 颜色值
        _WaterDeepColor ("WaterDeepColor", Color) = (0.2,0.2,0.2,1)

        _TranAmount ("TranAmount", Range(0, 100)) = 0.5 // 透明度
        _DepthRange ("DepthRange", Range(0, 10)) = 1 // 控制深度
        _NormalTex ("Normal", 2D) = "bump"{} // 法线贴图

        // 偏移 变量 控制 流动的 速度 
        _WaterSpeed("WaterSpeed", Range(0, 10)) = 3
        // 控制法线密集程度
        _Refract("Refract", Range(0, 1)) = 0.5
        // 高光
        _Specular ("Specular", Range(0,5)) = 1
        // 高光范围
        _Gloss ("Gloss", Range(0,100)) = 0.5
        // 高光 颜色
        _SpecularColor ("SpecularColor", Color) = (1,1,1,1)

        // 波浪
        _WaveTex ("WaveTex", 2D) = "white"{}
        // 噪声图
        _NioseTex ("NoiseTex", 2D) = "white"{}
        // 波浪速度
        _WaveSpeed("WaveSpeed", Range(0, 10)) = 1
        // 波浪范围
        _WaveRange("WaveRange", Range(0, 10)) = 0.5
        // 波浪范围 A
        _WaveRangeA("WaveRangeA", Range(0, 10)) = 1
        // 波浪范围 B
        _WaveRangeB("WaveRangeB", Range(0, 10)) = 1
        // 波浪 偏差值
        _WaveDelta("WaveDelta", Range(0, 10)) = 0.5


        // 抓屏 
        _Distortion ("Distortion", float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        GrabPass{"GrabPass"}// 抓屏

        ZWrite Off // 不写深度 ; 关闭 深度写入
        // Blend SrcAlpha OneMinusSrcAlpha // 透明混合



        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf Standard fullforwardshadows
        // waterLight 自定义 光照 替换 Standard ;  BlinnPhong 替换 Standard 的时候  SurfaceOutputStandard 要换成 SurfaceOutput
        // vertex 需要顶点 顶点着色器
        // alpha:fade 控制透明度
        // noshadow 关闭阴影
        #pragma surface surf WaterLight vertex:vert alpha noshadow



        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        // _CameraDepthTexture 定义深度图  需要配合 摄像机 使用; 需要 在摄像机 开启深度 纹理; 现在是 默认开启
        sampler2D_float _CameraDepthTexture;// sampler2D_float 是浮点纹理

        fixed4 _WaterShallowColor;// 浅水区 颜色值
        fixed4 _WaterDeepColor;// 浅水区 深度值
        half _TranAmount;
        float _DepthRange;
        sampler2D _NormalTex;// 法线贴图
        float _WaterSpeed; // 水流速度

        float _Refract; // 法线密集程度

        // 高光
        half _Specular;
        // 高光范围
        half _Gloss;
        // 高光 颜色
        fixed4 _SpecularColor;

        // 波浪图
        sampler2D _WaveTex;
        // 噪声图
        sampler2D _NoiseTex;
        // 波浪速度
        half _WaveSpeed;
        // 波浪范围
        half _WaveRange;

        // 波浪范围 A
        float _WaveRangeA;
        // 波浪范围 B
        float _WaveRangeB;
        // 波浪偏差值
        float _WaveDelta;



        sampler2D GrabPass;// 抓屏
        float4 GrabPass_TexelSize;// 抓屏纹理大小
        float _Distortion;// 抓屏偏移量





        struct Input
        {
            float2 uv_MainTex;
            float4 proj;// 顶点着色器 传出来的值
            float2 uv_NormalTex;// 法线
            float2 uv_WaveTexx;// 波浪
            float2 uv_NoiseTex;// 噪声
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // 自定义的 WaterLight; 会 自动拼写成 LightingWaterLight
        fixed4 LightingWaterLight(SurfaceOutput s, fixed3 lightDir, half3 viewDir, half atten) {

            
            float diffuseFactor = saturate(dot(normalize(lightDir), s.Normal));
            half3 halfDir = normalize(lightDir + viewDir);
            float nh = max(0, dot(halfDir, s.Normal));
            // spec 高光系数
            float spec = pow(nh, s.Specular * 128) * s.Gloss;//  为啥 乘以 128
            fixed4 c;
            c.rgb = (s.Albedo * _LightColor0.rgb * diffuseFactor + _SpecularColor.rgb * spec * _LightColor0.rgb) * atten;
            c.a = s.Alpha + spec * _SpecularColor.a;

            return c;
            
        }


        void vert(inout appdata_full v, out Input i) {
            // 初始化  Input i
            UNITY_INITIALIZE_OUTPUT(Input, i);
            // 屏幕空间的坐标
            i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
            // 计算摄像机 深度
            COMPUTE_EYEDEPTH(i.proj.z);// 顶点坐标 转到 视角屏幕空间 坐标 的 z 值
        }


        void surf (Input IN, inout SurfaceOutput o)
        {

            // SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UNITY_PROJ_COORD(IN.proj)); 用下面的  对屏幕空间 进行 深度图 采样 替换 这段代码

            // 对屏幕空间 进行 深度图 采样
            // 深度图渲染后一定是 在屏幕空间，对屏幕空间的 采样 使用 tex2Dproj
            // 他 的uv 要计算当前模型 在 顶点 着色器 里 画到屏幕上 之后 的 坐标，也就是说要获取到屏幕坐标上的 uv 才能进行采样
            half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.proj)).r);// 对深度图采样后 获取深度; LinearEyeDepth 将深度图采样后的值 转到 视角空间 的 深度值
            /////// tex2Dproj 与 tex2D 的区别是 tex2Dproj 的uv 是屏幕坐标，tex2D 的uv 是模型坐标；tex2Dproj 可以对屏幕空间进行采样，tex2D 只能对模型空间进行采样； tex2Dproj  是 tex2D 除以 .w
            /////// tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.proj)) == tex2D(_CameraDepthTexture, UNITY_PROJ_COORD(IN.proj / IN.proj.w))
            /////// 由于 计算出的来 深度值 是 非线性 的 所以 使用  LinearEyeDepth， 变换成 视角空间深度 的线性值

            // 具体的深度  depth 当前深度 - 顶点深度
            half deltaDepth = depth - IN.proj.z;//  平面的深度 减去 地形的深度 是 水的深度

            
            fixed4 c = lerp(_WaterShallowColor, _WaterDeepColor, min(_DepthRange, deltaDepth)/ _DepthRange);










            

            //// start === 法线计算
            // 要计算 流动的效果

            // 两次 流动方向 不一样， 所以要采样 两次，两次 的 uv 是不一样的

            // 先采样 第一次
            float4 bumpOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_WaterSpeed * _Time.x, 0));
            float4 bumpOffset2 = tex2D(_NormalTex, float2( 1-IN.uv_NormalTex.y, IN.uv_NormalTex.x) + float2(_WaterSpeed * _Time.x, 0));

            float4 offsetColor = (bumpOffset1 + bumpOffset2) / 2;// 得到偏移的额移动
            float2 offset = UnpackNormal(offsetColor).xy * _Refract;// 只获取 xy 的偏移
            
            float4 bumpColor1= tex2D(_NormalTex, IN.uv_NormalTex + offset + float2(_WaterSpeed * _Time.x, 0));
            float4 bumpColor2 = tex2D(_NormalTex, float2( 1-IN.uv_NormalTex.y, IN.uv_NormalTex.x) + offset  + float2(_WaterSpeed * _Time.x, 0));

            // o.Normal = UnpackNormal((bumpColor1 + bumpColor2) / 2).xyz;// 解码

            float3 normal = UnpackNormal((bumpColor1 + bumpColor2) / 2).xyz;// 解码

            //// end ==== 法线计算




            //// start === 计算波浪 ==波浪在 水的 边缘
            half waveA = min(_WaveRangeA, deltaDepth) / _WaveRangeA;
            half waveB = 1 - min(_WaveRangeB, deltaDepth) / _WaveRangeB;// 取反向

            // 噪声
            fixed4 noiseColor = tex2D(_NoiseTex, IN.uv_NoiseTex);


            // 对波浪图 进行采样 ; 因为 波浪图 是流动的 
            // 采样 两次
            // 第一次

            fixed4 waveColor = tex2D(_WaveTex, float(waveB + _WaveRange * sin(_Time.x * _WaveSpeed + noiseColor.r)) + offset);
            // 采样的 颜色值 做 sin 变化 ; sin(_Time.y * _WaveSpeed + noiseColor.r)) 是 -1 ~ 1 之间，所以 +1 除 2 是 0-1 之间
            waveColor.rgb *= (1- (sin(_Time.x * _WaveSpeed + noiseColor.r) + 1) / 2)  * noiseColor.r;

            // 第二次采样 ; _WaveDelta 是波浪的偏移量;采样 插值
            fixed4 waveColor2 = tex2D(_WaveTex, float(waveB + _WaveRange * sin(_Time.x * _WaveSpeed + _WaveDelta + noiseColor.r)) + offset);
            waveColor2.rgb *= (1- (sin(_Time.x * _WaveSpeed + _WaveDelta + noiseColor.r)+ 1) / 2 ) * noiseColor.r;






            // 两次 贴图采样 之后 和颜色 进行叠加

            //// end === 计算波浪



            //// start ==== 抓屏

            // 注意 抓屏 的 uv ，法线 
            offset = normal.xy * _Distortion * GrabPass_TexelSize.xy;
            IN.proj.xy = offset * IN.proj.z + IN.proj.xy;
            fixed3 refrCol = tex2D(GrabPass, IN.proj.xy / IN.proj.w).rgb; // 采样 GrabPass



            //// end ==== 抓屏




            

            o.Albedo =  ( c + (waveColor.rgb +  waveColor2.rgb) * waveB) * refrCol ;
            // o.Albedo =  ( c + (waveColor.rgb +  waveColor2.rgb) * waveB) * 1 ;


            //// start === 光照计算

            o.Normal = normal;
            o.Gloss = _Gloss;
            o.Specular = _Specular;


            //// end ==== 光照计算

            
            // Metallic and smoothness come from slider variables
            // o.Metallic = _Metallic;
            // o.Smoothness = _Glossiness;
            // o.Alpha = c.a * _TranAmount;
            o.Alpha = min(_TranAmount, deltaDepth) /_TranAmount;
        }
        ENDCG
    }
    FallBack "Diffuse"
}


// 第一步 对深度图的 采样
// 摄像机会把 深度 放到一张图里 ，对他来采样 可以得到 水 距离 岸边浅 的 颜色会 淡 ，深的 地方颜色 会 深


// 波浪需要 贴图采样
// 还需要 噪声 