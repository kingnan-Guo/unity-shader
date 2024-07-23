// Shader "Unlit/CGFile"
// {
//     Properties
//     {
//         _MainTex ("Texture", 2D) = "white" {}
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

//             v2f vert (appdata v)
//             {
//                 v2f o;
//                 o.vertex = UnityObjectToClipPos(v.vertex);
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



Shader "Unlit/CGFile"
{
    Properties
    {
        _myInt("Int", Int) = 10
        _myColor("Color", Color) = (1,1,0,1)
        _myFloat("Float", Range(0, 100)) = 50
        _myVector("Vector", Vector) = (1,1,1,1)

        _My2D("2D", 2D) = "" {}
        _My3D("3D", 3D) = "" {}
        _MyCube("Cube", Cube) = "" {}
        _My2DArray("My2DArray", 2DArray) = ""{}
        _MyRange("Range", Range(0, 100)) = 50
        // _My2DRange("2D Range", 2D) = (0,0,100,100)
        // _My3DRange("3D Range", 3D) = (0,0,0,100,100,100)
        _myTexture("Texture", 2D) = "white" {}

    }

    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"



            //声明 对应属性的 同名 变量
            float _myInt;
            fixed4 _myColor;
            float _myFloat;
            float4 _myVector;
            sampler2D _My2D;


            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            // 从顶点着色器 传递给 片元着色器 的 结构体数据
            // 需要语义进行修饰
            struct v2f
            {
                // 裁剪空间下的坐标
                float4 posituon : SV_POSITION;
                // 模型顶点坐标
                // float3 vertex : POSITION;
                // 模型顶点法线
                float3 normal : NORMAL;
                // 模型顶点纹理坐标
                float2 uv : TEXCOORD0;
            };

            // 顶点着色器
            // POSITION 和 SV_POSITION 是 CG 语言的 语义
            // POSITION 把模型顶点坐标 填充到 输入的参数 vertex 中
            // SV_POSITION  顶点着色器输出的内容是 剪裁空间中的顶点 坐标

            // 该着色器 时从应用阶段 获取对应语义 数据后 传递给 顶点 着色器 回调函数
            // v2f vert (a2v data)
            // {
            //     // 需要传递给 片元着色器的数据
            //     v2f v2fData;
            //     v2fData.posituon = UnityObjectToClipPos(data.vertex);
            //     // v2fData.vertex = data.vertex;
            //     v2fData.normal = data.normal;
            //     v2fData.uv = data.uv;
            //     return v2fData;
            // };

            v2f_img vert (appdata_base data)
            {
                // 需要传递给 片元着色器的数据
                v2f_img v2fData;
                v2fData.pos = UnityObjectToClipPos(data.vertex);
                // v2fData.vertex = data.vertex;
                // v2fData.normal = data.normal;
                v2fData.uv = data.texcoord;
                return v2fData;
            };


            // 片元着色器
            // SV_Target 是 渲染器 要求的输出参数; 告诉渲染器 把用户输出颜色存储到 一个渲染目标中，这里将输出到 默认的 帧 缓存中
            // 这里的 data 时 v2fData 的数据
            fixed4 frag (v2f_img data) : SV_Target
            {

                // 输出颜色 模型顶点 对应的坐标信息
                fixed4 color = tex2D(_My2D, data.uv);
                return color;
                // return _myColor;
            }
            ENDCG
        }

    }

}
// unityCG.cginc 常用帮助函数 宏 和 结构体
// Lighting.cginc  光照模型 如果是 写 surface shander 会自动包含进来
// unityShaderVariable.cginc 编译 unityshader 时会自动包含进来 有许多的全局变量
// HLSLSupport.cginc           编译 unityshader  包含了很多跨平台的 宏定义

// #include "文件.cginc"


//-------------
// float3 WorldSpaceViewDir(float4 v)
// // 输入一个模型空间的顶点位置，返回世界空间中 从该顶点位置指向摄像机 的向量
// {
//     // 模型空间 顶点位置 减去 观察者位置
//     // 观察者位置 存储在 _WorldSpaceCameraPos 全局变量中
//     return normalize(v.xyz - _WorldSpaceCameraPos);
// }

// float3 ObjSpaceViewDir(float4 v)
// // 输入一个模型空间的顶点位置，返回模型空间中 从该顶点位置指向观察者的向量
// {
    
// }

// //-------------
// float3 WorldSpaceLightDir(float4 v)
// // 输入一个模型空间的顶点位置，返回世界空间中 从该顶点位置指向光源的向量
// {
//     // 模型空间 顶点位置 减去 光源位置
//     // 光源位置 存储在 _WorldSpaceLightPos0 全局变量中
//     return normalize(v.xyz - _WorldSpaceLightPos0);
// }

// float3 ObjSpaceLightDir(float4 v)
// // 输入一个模型空间的顶点位置，返回模型空间中 从该顶点位置指向光源的向量
// {
    
// }

// //-------------
// float3 TangentToWorld(float3 tangent, float3 normal, float4 tangentToWorld)
// // 输入一个切线向量，一个法线向量，一个 变换矩阵，返回变换后的切线向量
// {
//     // 变换矩阵 乘以 切线向量
//     return mul(tangent, tangentToWorld);
// }



// float3 WorldToTangent(float3 world, float3 normal, float4 tangentToWorld)
// // 输入一个世界空间中的向量，一个法线向量，一个 变换矩阵，返回变换后的切线向量
// {
//     // 变换矩阵 乘以 切线向量
//     return mul(world, tangentToWorld);
// }

// //-------------
// float3 ObjectToTangent(float3 object, float3 normal, float4 tangentToWorld)
// // 输入一个模型空间中的向量，一个法线向量，一个 变换矩阵，返回变换后的切线向量
// {
//     // 变换矩阵 乘以 切线向量
//     return mul(object, tangentToWorld);
// }

// float3 UnityObjectToWorldNormal(float3 normal)
// // 输入一个模型空间中的法线向量，返回变换后的法线向量； 把法线从模型空间 转到世界空间
// {
//     // 变换矩阵 乘以 法线向量
//     return mul(normal, _World2Object);
// }

// float3 UnityObjectToWorld(float3 vertex)
// // 输入一个模型空间中的顶点位置，返回变换后的顶点位置
// {
//     // 变换矩阵 乘以 顶点位置
//     return mul(vertex, _World2Object);
// }

// float3 UnityObjectToWorldDir(float3 dir)
// // 输入一个模型空间中的向量，返回变换后的向量; 方向向量 从模型 转到 世界空间
// {
//     // 变换矩阵 乘以 向量
//     return mul(dir, _World2Object);
// }

// float3 UnityWorldToObjectNormal(float3 normal)
// // 输入一个世界空间中的法线向量，返回变换后的法线向量； 把法线从世界空间 转到模型空间
// {
//     // 变换矩阵 乘以 法线向量
//     return mul(normal, _Object2World);
// }


// float3 UnityWorldToObject(float3 vertex)
// // 输入一个世界空间中的顶点位置，返回变换后的顶点位置
// {
//     // 变换矩阵 乘以 顶点位置
//     return mul(vertex, _World2Object);
// }

// float3 UnityWorldToObjectDir(float3 dir)
// // 输入一个世界空间中的向量，返回变换后的向量
// {
//     // 变换矩阵 乘以 向量
//     return mul(dir, _World2Object);
// }



// 还有 一些结构体

// appdata_base


// /====

// 变换矩阵宏
// 坐标空间变换顺序
// 模型空间 -> 世界空间 -> 观察空间 -> 裁剪空间  -> 屏幕空间

// UNITY_MATRIX_MVP 当前模型 * 观察* 投影 ; 用于将顶点 / 方向 向量从模型空间 变换到 剪裁空间

// UNITY_MATRIX_MV 当前模型 * 观察矩阵  用于将顶点 / 方向 向量从模型空间 变换到 观察空间

// UNITY_MATRIX_V 当前 观察矩阵, 用于将顶点 / 方向 向量从 世界空间 变换到 观察空间

// UNITY_MATRIX_P 当前 投影矩阵, 用于将顶点 / 方向 向量从 观察空间 变换到 裁剪空间

// UNITY_MATRIX_VP 当前 观察 * 投影矩阵, 用于将顶点 / 方向 向量从 世界空间 变换到 裁剪空间

// UNITY_MATRIX_T_MV 当前 观察 * 模型矩阵的逆矩阵, 

// UNITY_MATRIX_IT_MV 当前 观察 * 模型矩阵的逆矩阵的转置, 用于从模型空间变换到观察空间, 也可以用

// UNITY_MATRIX_M 当前 模型矩阵, 用于将顶点 / 方向 向量从 模型空间 变换到 世界空间

// _Object2World 当前 模型矩阵,用于将顶点 / 方向 向量从 模型空间 变换到 世界空间

// _World2Object:  _Object2World 的 逆矩阵 当前 模型矩阵的逆矩阵, 用于将顶点 / 方向 向量从 世界空间 变换到 模型空间

// _World2Object 当前 模型矩阵的逆矩阵的转置, 用于将顶点 / 方向 向量从 世界空间 变换到 模型空间


///======== 变量

// _Time 当前时间 不用引用直接使用
//     自关卡 加载以来 的事件 t/20 t*2 t*3 用于对着色器内的事物 进行动画处理
//     _Time.y 当前时间 秒数
//     _Time.x 当前时间 毫秒


    

// _SinTime 当前时间的正弦值

// _CosTime 当前时间的余弦值

// _WorldSpaceCameraPos 世界空间中的相机位置

// _WorldSpaceLightPos0 世界空间中的 光源位置

// _ObjectSpaceCameraPos 模型空间中的相机位置

// _WorldSpaceLightPos0 世界空间中的 光源位置

// _LightPos0 世界空间中的 光源位置 (向前渲染时 unityLightingCommon.cginc 延迟 渲染 unityDeferredLiabrry.cginc); 光的颜色

// _LightPos1 世界空间中的 光源位置