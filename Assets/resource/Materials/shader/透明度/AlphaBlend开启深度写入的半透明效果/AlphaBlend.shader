Shader "Unlit/AlphaBlend"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {} // 纹理
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)

        _AlphaScale("Alpha Scale", Range(0, 1)) = 0.5//透明度

        _Specular("Specular", Color) = (1, 1, 1, 1)// 高光 
        _Gloss("Gloss", Range(1, 256)) = 1
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent" // 确定渲染顺序 Queue 渲染队列， Transparent 透明度 混合的物体 在此 绘制
            "IgnoreProjector"="True" // 忽略投影
            "RenderType"="Transparent" // 渲染队列
        }
        LOD 100

        
        
        



        // 两个 pass 通道 进行 渲染

        // 第一个 pass 通道
        // 用来写入深度值
        // 因为透明物体需要深度测试，所以需要写入深度值
        // 但是透明物体需要深度写入，所以需要关闭颜色写入
        Pass{
            ZWrite On// 开启深度写入
            ColorMask 0// 掩码遮罩； 意味着 不写入 任何 颜色通道
        }

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha // 透明混合 ; SrcAlpha 因子 为 源颜色的 透明度值 ； OneMinusSrcAlpha 因子 为 1 - 源颜色的 透明度值

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"// 包含光照计算函数

            sampler2D _MainTex;// 纹理
            float4 _MainTex_ST;// 是 _MainTex 的附属物 ，包含纹理的缩放和偏移

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            float _AlphaScale;// 透明度

            struct v2f
            {
                float4 vertex : SV_POSITION;// 顶点
                fixed3 worldNormal : TEXCOORD0;// 法线
                float3 worldPosition : TEXCOORD1;// 世界顶点位置

                float2 uv : TEXCOORD2;//TEXCOORD2 语义:获取该模型纹理坐标 ； 用模型的 第三套 纹理坐标填充 TEXCOORD2
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                o.worldNormal = worldNormal;
                // o.worldPosition = UnityObjectToWorldDir(v.vertex);// 顶点位置 （世界 空间）
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                // 让 外面的数值 可以影响到 uv
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;// 纹理坐标 ; https://www.lfzxb.top/unity-shader-base-texcoordn/
                // 替换上面
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);// 纹理坐标；也就是俗称的UV，是顶点数据的一部分； uv和有没有贴图没关系哦，uv是网格的属性
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;


                // 纹理图片采样 =========== 
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从_Bump纹理中提取法向信息
                fixed4 texColor = tex2D(_MainTex, i.uv);// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 


                // 漫反射 ==============
                // 光源方向
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);// _WorldSpaceLightPos0 世界光源方向; 归一化
                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPosition);


                fixed3 worldNormal = normalize(i.worldNormal);// 归一化

                // fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * texColor.rgb * _Diffuse.rgb * (dot(worldLightDir, i.worldNormal) * 0.5 + 0.5);


                // 高光反射
                fixed3 reflectDir = normalize(reflect(-worldLightDir, i.worldNormal));
                

                // 视角方向
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));


                // 半角向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);// 光源向量 +  视角向量
              
                // 高光颜色
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfDir)), _Gloss);


                // texColor.a  这里的a 应该是  alpha 透明度

                // fixed3 color = diffuse + ambient + specular;
                fixed3 color = diffuse + ambient;// 可以去掉 高光
                return fixed4 (color, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}
