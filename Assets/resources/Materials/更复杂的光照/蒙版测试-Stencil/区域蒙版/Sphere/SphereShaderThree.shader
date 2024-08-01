Shader "Unlit/SphereShaderThree"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 蒙版参考值
        _refVal("Stencil Reference Value", Range(0, 10)) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
             // 渲染 顺序 Geometry: 2000; Geometry+1 = 2001

            Tags{"LightMode"="ForwardBase" "Queue"="Geometry+1"}
            
            // ColorMask 0 //ColorMask  选择颜色遮罩的 关键字； 0： 关闭颜色写入 不输出 任何颜色； 1：开启颜色写入
            Stencil{
                Ref [_refVal]// 参考值； 第一次 渲染 原本的  参考值 是 0 ; 此像素位置的缓冲值
                Comp Equal     // 比较成功 条件： 大于等于
                // Pass Keep    // 通过蒙版测试： 把当前的 值 写入到 蒙版测试里 STENCILENBLE
                // Fail Keep       // 保持
                // ZFail Keep      // 保持
            }



            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}


// 此处 渲染顺序 是  先渲染 背景  然后 球体 然后cube 因为 
// 背景  2000  球体 2001 cube 2002