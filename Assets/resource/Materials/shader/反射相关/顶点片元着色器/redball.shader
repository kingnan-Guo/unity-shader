// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/redball"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 顶点着色器
            // POSITION 和 SV_POSITION 是 CG 语言的 语义
            // POSITION 把模型顶点坐标 填充到 输入的参数 vertex 中
            // SV_POSITION  顶点着色器输出的内容是 剪裁空间中的顶点 坐标
            // 如果没有语义来限定 输入和 输出 参数的话，那么渲染器就完全不知道 用户输入输出的 是什么
            float4 vert (float4 vertex : POSITION) : SV_POSITION
            {
                // mul 是CG 语言 提供 的矩阵 和向量的 乘法运算函数 （就是一个 内置的函数）
                //  UNITY_MATRIX_MVP  代表一个变换矩阵， 是unity 内置模型，观察、投影矩阵 变化
                //  UnityObjectToClipPos 是 mul(UNITY_MATRIX_MVP, vertex) 的 函数封装
                // return mul(UNITY_MATRIX_MVP, vertex);
                // vertex.x = vertex.x + 0.5;
                // vertex.y = vertex.y + 0.5;
                // vertex.z = vertex.z + 0.5;
                // vertex.w = vertex.w + 0.5;
                // return vertex;
                return UnityObjectToClipPos(vertex);
            }

            // 片元着色器
            // SV_Target 是 渲染器 要求的输出参数; 告诉渲染器 把用户输出颜色存储到 一个渲染目标中，这里将输出到 默认的 帧 缓存中
            // 片元着色器 负责 计算 像素的颜色
            // 片元着色器 输入参数 就是 顶点着色器 输出的 内容
            // 片元着色器 输出参数 就是 渲染器 要求的输出参数
            fixed4 frag () : SV_Target
            {
                return fixed4(0,0,1,1);
            }
            ENDCG
        }

    }

}

// CG 语言中 提供了 语义这种 特殊 关键字 用于修饰函数中的 传入参数和返回参数
// 应用阶段 传递模型数据给顶点做瑟琪时 unity 支持的 语义
// 一般顶点 着色器回调函数 的 传入参数应用
// POSITION 模型顶点坐标   float4
// NORMAL 模型顶点法线     float3
// TANGENT 模型顶点切线    float4
// TEXCOORDn 模型顶点纹理坐标
    
//     顶点的 纹理左边通常是 float2 或者 float4
//     TEXCOORD0 第一组 模型顶点纹理坐标
//     TEXCOORD1 第二组 模型顶点纹理坐标 
//     纹理也称 UV 坐标，表示 该顶点对应纹理图像上的 位置

// COLOR
//     顶点的 颜色


// 顶点着色器 ——>片元着色器
// 从顶点着色器 传递数据给 偏远着丝琪时 unity 支持语义
// 一般在顶点着色器回调函数的 返回值 中应用
// SV_POSITION 剪裁空间中的 顶点坐标（必备）

// COLOR0 通常用来输出 第一组 颜色 （非必须）
// COLOR1 通常用来输出 第二组 颜色 （非必须）

// TEXCOORD0~7 通常用来输出 第一组到 第七组  纹理坐标 非必须


// 片元着色器 输出
// 输出值 会存储到渲染目标中


// 更多语义 HLSL 语义相同


