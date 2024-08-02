Shader "Unlit/stenciDemoOne"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // 蒙版参考值
        _refVal("Stencil Reference Value", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            Tags{
                "LightMode"="ForwardBase"
                "Quene"="2" // 测试渲染 顺序
            }

            //为了 不影响 模板测试 先把 深度测试关掉
            ZTest Always
            // ZWrite Off

            Stencil{
                
                Ref [_refVal]// 参考值； 第一次 渲染 原本的  参考值 是 0 ; 此像素位置的缓冲值
                Comp GEqual     // 比较成功 条件： 大于等于
                Pass Replace    // 通过蒙版测试： 把当前的 值 写入到 蒙版测试里 STENCILENBLE
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

//相同  的 Queue  那么 越 靠近摄像机 越 先渲染； 
// cube 和 sp 都是 2的时候   cube 距离摄像机更近一些 所以先渲染

// https://www.cnblogs.com/FlyingZiming/p/12937642.html
// 模板缓冲区默认值为0（测试得到），并且我推测模板缓冲区每帧执行完会进行一个刷新


// Stencil{    
//     Ref 1
//     Comp Equal
//     Pass Keep
// }

// 上述代码的意思是: 我们自己设定了 Ref 参考值为 1。渲染 Pass 得到像素颜色后，拿参考值 1 与模板缓冲中 此像素位置的缓冲值 比对，只有 Equal 相等才算通过，并且 Keep 保持原有缓冲值，否则丢弃此像素颜色。


// 个人理解  默认的 对比 值 是 0
// 所以 在 Equal 情况下 ; ref 设置 1 不会展示 ，ref 设置 0  才会 展示
// 在 GEqual 情况下 ; ref 设置 1 会展示 ， ref 设置 0 也会展示
