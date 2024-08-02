Shader "Custom/addVertNewSurfaceShader"
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
        // #pragma surface surf Standard fullforwardshadows vert:vert finalcolor:final
        #pragma surface surf Ocean fullforwardshadows vert:vert finalcolor:final

        


        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"// 添加  UnityPBSLight 解決 SurfaceOutputStandard 沒有定義的錯誤

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
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        // 添加 頂點修改
        void vert(inout appdata_full v){

        }



        void final(Input IN, SurfaceOutputStandard o, inout fixed4 color)
        {
            // 处理颜色的代码
        }


        // 更改 光照  蘭伯特
        half4 LightingOcean (SurfaceOutputStandard s, half3 lightDir, half3 viewDir, half atten){
            fixed4 c;
            fixed diff = max(0, dot(s.Normal, lightDir));
            c.rgb = s.Albedo * _LightColor0.rgb * diff * atten;
            c.a = s.Alpha;
            return c;
        }


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


// vert:vert 表明 頂點修改