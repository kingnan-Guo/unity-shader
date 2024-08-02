Shader "Custom/NewSurfaceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows // 后面可以添加 多个 操作符 可以生成 对应的 pass 通道; 最终 会 编译成 多个 pass 通道； 不需要写 include 会 自动去 包含

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props) // 宏定义 做 GPUInstancing
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props) // 宏定义 做 GPUInstancing

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}


// #pragma surface surf Standard fullforwardshadows [optionalparams]

// surface                  表明当前是一个 surface Shader
// surf                     surface 最主要的函数     必须要指定的
// Standard（LightModel）   unity 自带的 光照模型    必须要指定的;由于 Unity 内置了一些 光照函数  ----Lambert （diffuse）和 Blinn-Phong（specular），因此在这里默认情况下 会使用内置 的 Lambert 模型 ，当然也可以自定义
// fullforwardshadows       前向渲染所有的 阴影  （可选）
// [optionalparams] 包含了 很多的指令类型。 包括开启 、关闭 一些状态 ，设置 生成 pass 类型， 指定可选 函数等，除了 上述 的 surfaceFunction 和 LightModel ，我们 还可以自定义两种函数： Vertex ： VertexFunction （获取到顶点， 可以进行一些动画）  和 finalColor： ColorFunction (最终颜色的 修改),也就是 说  Surface shader 允许我们自定义 四种函数






// SurfaceOutputStandard 结构体 ；
// SurfaceOutputStandard 是一个结构体，它包含了 Standard 光照模型所需要的所有信息。它包含了以下成员：
// Albedo：漫反射颜色，即物体表面的基本颜色。
// Metallic：金属度，用于控制物体表面的金属质感。
// Smoothness：光滑度，用于控制物体表面的光滑程度。
// AmbientOcclusion：环境光遮蔽，用于控制物体表面的阴影效果。
// Emission：自发光，用于控制物体表面的自发光效果。
// Alpha：透明度，用于控制物体表面的透明效果。