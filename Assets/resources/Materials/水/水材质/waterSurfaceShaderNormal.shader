Shader "Custom/waterSurfaceShader"
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

        _TranAmount ("TranAmount", Range(0, 1)) = 0.5 // 透明度
        _DepthRange ("DepthRange", Range(0, 10)) = 1 // 控制深度
        _NormalTex ("Normal", 2D) = "bump"{} // 法线贴图

        // 偏移 变量 控制 流动的 速度 
        _WaterSpeed("WaterSpeed", Range(0, 10)) = 3
        // 控制法线密集程度
        _Refract("Refract", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        ZWrite Off // 不写深度 ; 关闭 深度写入
        // Blend SrcAlpha OneMinusSrcAlpha // 透明混合


        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf Standard fullforwardshadows
        // waterLight 自定义 光照 替换 Standard ;  BlinnPhong 替换 Standard 的时候  SurfaceOutputStandard 要换成 SurfaceOutput
        // vertex 需要顶点 顶点着色器
        // alpha:fade 控制透明度
        // noshadow 关闭阴影
        #pragma surface surf BlinnPhong vertex:vert alpha noshadow



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




        struct Input
        {
            float2 uv_MainTex;
            float4 proj;// 顶点着色器 传出来的值
            float2 uv_NormalTex;
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
            half deltaDepth = depth - IN.proj.z;// 老师说 平面的深度 减去 地形的深度 是 水的深度？？ 摄像机深度 减去 物体深度值？？？ 上进行对比 才知道 哪个地方深 

            
            fixed4 c = lerp(_WaterShallowColor, _WaterDeepColor, min(_DepthRange, deltaDepth)/ _DepthRange);
            o.Albedo = c.rgb;

            //// start === 法线计算
            // 要计算 流动的效果

            // 两次 流动方向 不一样， 所以要采样 两次，两次 的 uv 是不一样的

            // 先采样 第一次
            float4 bumpOffset1 = tex2D(_NormalTex, IN.uv_NormalTex + float2(_WaterSpeed * _Time.y, 0));
            float4 bumpOffset2 = tex2D(_NormalTex, float2( 1-IN.uv_NormalTex.y, IN.uv_NormalTex.x) + float2(_WaterSpeed * _Time.y, 0));

            float4 offsetColor = (bumpOffset1 + bumpOffset2) / 2;// 得到偏移的额移动
            float2 offset = UnpackNormal(offsetColor).xy * _Refract;// 只获取 xy 的偏移
            
            float4 bumpColor1= tex2D(_NormalTex, IN.uv_NormalTex + offset + float2(_WaterSpeed * _Time.y, 0));
            float4 bumpColor2 = tex2D(_NormalTex, float2( 1-IN.uv_NormalTex.y, IN.uv_NormalTex.x) + offset  + float2(_WaterSpeed * _Time.y, 0));

            o.Normal = UnpackNormal((bumpColor1 + bumpColor2) / 2).xyz;// 解码

            //// end ==== 法线计算

            // Albedo comes from a texture tinted by color
            // fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            
            // Metallic and smoothness come from slider variables
            // o.Metallic = _Metallic;
            // o.Smoothness = _Glossiness;
            o.Alpha = c.a * _TranAmount;
        }
        ENDCG
    }
    FallBack "Diffuse"
}


// 第一步 对深度图的 采样
// 摄像机会把 深度 放到一张图里 ，对他来采样 可以得到 水 距离 岸边浅 的 颜色会 淡 ，深的 地方颜色 会 深
