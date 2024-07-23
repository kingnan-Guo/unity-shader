Shader "Unlit/CGInnerFunction"
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

                // 输出颜色 模型顶点 对应的坐标信息
                fixed4 color = tex2D(_My2D, data.uv);
                return color;
                // return _myColor;
            }
            ENDCG
        }

    }

}

// CG 内置函数
// 1. 三角函数      sincos(float angle, out float s, out float c)
// 2. 指数函数      
// 3. 幂函数
// 4. 平方根函数
// 5. 绝对值函数
// 6. 三角函数
// 向量 矩阵相关
// cross 
// dot
// length
// normalize
// mul                 
// mul(M,N)            矩阵和矩阵相乘
// mul(M,V)             mul(M,V) 矩阵和向量相乘
// mul(v,M)             向量和 矩阵相乘
// mul(M,P)             mul(M,P) 矩阵和点相乘

// transpose(M)           M 转置
// determinant         矩阵行列式因子
// inverse


// 数值相关
// abs(x)
// acos(x)
// asin(x)
// atan(x)
// atan2(y,x)
// ceil(x)
// clamp(x,a,b)
// cos(x)
// cosh(x)
// floor(x)
// fmod(x,y)
// frac(x)
// lerp(a,b,t)
// log(x)
// log10(x)
// max(a,b)
// min(a,b)
// pow(x,y)
// round(x)
// saturate(x)




// // 其他
// lit(NdotL, NdotH, m)    N表示法向量 L表示射光向量 H表示半角向量 m表示材质反射系数
//                         该函数计算 环境光 散射光 镜面光 返回 4为向量
//                         x位 表示 光贡献
//                         y位 表示 环境光 散射光 镜面光 贡献


// // 纹理相关
// tex2D
// tex2Dproj
// tex2Dlod
// tex2Dprojlod
// tex2Dgrad
// tex2Dprojgrad
// tex2Dlod
// tex2Dprojlod
// tex2Dgrad
// tex2Dprojgrad
// tex3D
// tex3Dproj


二维纹理
// tex2D(sampler2D tex, float2 s) // 二维纹理 采样
// tex2D(sampler2D tex, float2 s, float2 d) // 二维纹理 采样
// tex2Dproj
// tex2Dproj(sampler2D tex, float4 s) // 二维纹理 采样
// tex2Dproj(sampler2D tex, float4 s, float2 d) // 二维纹理 采样
// tex2Dlod
// tex2Dlod(sampler2D tex, float4 s) // 二维纹理 采样
// tex2Dlod(sampler2D tex, float4 s, float2 d) // 二维纹理 采样
// tex2Dgrad
// tex2Dgrad(sampler2D tex, float2 s, float2 d) // 二维纹理 采样
// tex2Dgrad(sampler2D tex, float2 s, float2 d, float2 t) // 二维纹理 采样
// tex2Dprojgrad
// tex2Dprojgrad(sampler2D tex, float4 s, float2 d) // 二维纹理 采样
// tex2Dprojgrad(sampler2D tex, float4 s, float2 d, float2 t) // 二维纹理 采样


三维纹理
tex3D(sampler3D tex, float3 s) // 三维纹理 采样
tex3D(sampler3D tex, float3 s, float3 d) // 三维纹理 采样