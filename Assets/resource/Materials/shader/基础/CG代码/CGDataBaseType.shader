Shader "Unlit/CGDataBaseType"
{
    Properties
    {

    }
    SubShader
    {


        Pass
        {
            CGPROGRAM

            void aaa ()
            {


                // 基础数据类型
                uint a = 1;
                int b = -2;
                float c = 3.0f;// 32位浮点数 
                bool d = true;
                fixed e = 4.0;// 12 位 浮点数
                half f = 5.0h;// 16位 浮点数
                fixed4 g = 6.0;
                half4 h = 7.0;
                float4 i = 8.0;
                float4x4 j = 9.0;
                float3x3 k = 10.0;
                float2x2 l = 11.0;

  


                float arrayf[3] = {1,2,3};

                float arrff[2][2] = {{1, 2}, {2, 3}};
                // arrff.length
                // arrff[0].length

  
                fixed2 f2 = fixed2(1.2, 2.5);

                float3 f3 = float3(1.2, 2.5, 3.6);

                // 矩阵  不大于 4  不小于 11
                int2x3 mint2x3 = {
                    1,2,3,
                    4,5,6
                };


                // bool 类型同样可以 用于 如同 向量一样声明
                // bool3 a = bool3(true, false, true);
                // float3 aa = float (1, 2, 3);
                // float3 bb = float (4, -5, 6);
                // bool cc = aa < bb;
            }

            ENDCG
        }
    }
}
// 基础 数据类型