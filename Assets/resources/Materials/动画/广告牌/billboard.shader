Shader "Unlit/billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        // 引文 _Verical 除了0 就是 1 ，所以要加 MaterialToggle
        [MaterialToggle]_Verical ("Verical", Range(0, 1)) = 0.5

    }

    SubShader
    {
        // 半透明

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off // 关闭背面剔除；两个面都渲染
        Tags {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProjector"="True" // 我们不希望任何投影类型材质或者贴图，影响我们的物体或者着色器
            "DisableBacthing"="True" // 为了不影响顶点计算，关闭合批，防止部分顶点被合并; 一般做一些顶点相关的 计算 都要关闭掉
        }
        LOD 100

        Pass
        {
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
            fixed _Verical;

            v2f vert (appdata v)
            {
                v2f o;

                // 寻找锚点
                float3 center = float3(0, 0, 0);
                // 模型空间对应视角方向 
                float3 viewDir = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                float3 normalDir = viewDir - center;
                normalDir.y = normalDir.y * _Verical;
                normalDir = normalize(normalDir);// 归一化


                // 先找到 虚拟的 向上的 向量 upDir， 如果 normalDir.y 为 1，那么 upDir 就为 float3(0, 0, 1) 应该是 Z 轴，但是为什么是 Z 轴 ，否则 upDir 就为 float3(0, 1, 0)
                // 如果  normalDir.y 那么 他就是 Y 轴，所以另一个轴 是  (0,0,1) Z轴，或者 (1,0,0) X轴
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);

                // 这时 可以 计算出  right 的方向
                float3 rightDir = normalize(cross(upDir, normalDir));
                // 计算出 真实  的 up 方向
                float3 realUpDir = normalize(cross(normalDir, rightDir));

                // 计算出中心 偏移 位置
                float3 centerOffset = v.vertex.xyz  - center;

                // 计算出 顶点 要如何 变换; 得到 旋转之后  的 顶点 位置
                // 向量 乘 单位向量  是 
                float3 localPos = center + rightDir * centerOffset.x + realUpDir * centerOffset.y + normalDir * centerOffset.z;




                // o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = UnityObjectToClipPos(localPos);
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



// 向量叉乘
// A向量 B向量 叉乘
// A 与 B 所形成的 平面 的 法向量

// 需要 三个相互 正交 的 积向量



// Shader "Unlit/billboard"
// {
//     Properties
//     {
//         _MainTex ("Texture", 2D) = "white" {}
// 		[MaterialToggle]_Vertical("Vertical",Range(0,1)) = 1//约束垂直方向的程度
//     }
//     SubShader
//     {
// 		//通常是透明背景，所以需要设置pass的相关状态，以渲染透明效果
// 		//为了不影响顶点计算，关闭合批，防止部分顶点被合并
//         Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjection"="True" "DisableBacthing"="True" }
//         LOD 100

//         Pass
//         {
// 			ZWrite Off
// 			Blend SrcAlpha OneMinusSrcAlpha
// 			Cull Off

//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             // make fog work
//             #pragma multi_compile_fog

//             #include "UnityCG.cginc"

//             struct appdata
//             {
//                 float4 vertex : POSITION;
//                 float2 uv : TEXCOORD0;
//             };

//             struct v2f
//             {
//                 float2 uv : TEXCOORD0;
//                 UNITY_FOG_COORDS(1)
//                 float4 vertex : SV_POSITION;
//             };

//             sampler2D _MainTex;
//             float4 _MainTex_ST;
// 			fixed _Vertical;

//             v2f vert (appdata v)
//             {
//                 v2f o;
// 				float3 center = float3(0, 0, 0);//模型中心点
// 				float3 view = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));//世界空间视角方向转为模型空间视角方向

// 				float3 normalDir = view - center;//表面法线，从模型的中心点到模型空间视角的方向向量
// 				//_Vertical为0时，法线方向为水平方向，所以quad面片只能在水平方向旋转
// 				//_Vertical为1时，法线方向可以是任意方向，所以无论摄像机在什么方向，quad面片都面向摄像机
// 				normalDir.y = normalDir.y*_Vertical;
// 				normalDir = normalize(normalDir);//归一化

// 				//获得粗略的向上方向，为了防止法线方向和向上方向平行(如果平行，叉积会得到错误的结果)，对法线方向的y分量进行判断
// 				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
// 				//根据法线方向和粗略的向上方向得到向右方向，并归一化
// 				float3 rightDir = normalize(cross(upDir, normalDir));
// 				//根据法线方向和向右方向获得准确的向上方向
// 				upDir = normalize(cross(normalDir, rightDir));
// 				//根据原始的位置相对于锚点的偏移量以及3个正交基矢量，以计算得到新的顶点位置
// 				float3 centerOffset = v.vertex.xyz - center;
// 				float3 localPos = center + rightDir * centerOffset.x + upDir * centerOffset.y + normalDir * centerOffset.z;
// 				//把模型空间的顶点位置变换到裁剪空间
//                 o.vertex = UnityObjectToClipPos(float4(localPos,1));
//                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                 UNITY_TRANSFER_FOG(o,o.vertex);
//                 return o;
//             }

//             fixed4 frag (v2f i) : SV_Target
//             {
//                 // sample the texture
//                 fixed4 col = tex2D(_MainTex, i.uv);
//                 // apply fog
//                 UNITY_APPLY_FOG(i.fogCoord, col);
//                 return col;
//             }
//             ENDCG
//         }
//     }
// }

