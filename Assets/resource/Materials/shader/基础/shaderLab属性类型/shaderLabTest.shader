Shader "Unlit/MultipleData"
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

            //声明 对应属性的 同名 变量
            float _myInt;
            fixed4 _myColor;
            float _myFloat;
            float4 _myVector;

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
            v2f vert (a2v data)
            {
                // 需要传递给 片元着色器的数据
                v2f v2fData;
                v2fData.posituon = UnityObjectToClipPos(data.vertex);
                // v2fData.vertex = data.vertex;
                v2fData.normal = data.normal;
                v2fData.uv = data.uv;
                return v2fData;
            };

            // 片元着色器
            // SV_Target 是 渲染器 要求的输出参数; 告诉渲染器 把用户输出颜色存储到 一个渲染目标中，这里将输出到 默认的 帧 缓存中
            // 这里的 data 时 v2fData 的数据
            fixed4 frag (v2f data) : SV_Target
            {
                return _myColor;
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


// ======= CG中变量类型对应 shaderLab 的属性类型
// CG中变量类型对应 shaderLab 的属性类型
// shaderLab 属性类型           CG变量类型
// Color, Vector               float4, half4, fixed4
// Range, Float, Int           float, half, int
// 2D,                         sampler2D
// 3D,                         sampler3D
// Cube,                       samplerCUBE
// 2DArray                     sampler2DArray
// CubeArray                   samplerCUBEArray
// Texture                     sampler2D
