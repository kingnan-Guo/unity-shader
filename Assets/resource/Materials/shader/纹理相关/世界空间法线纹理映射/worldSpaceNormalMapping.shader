Shader "Unlit/worldSpaceNormalMapping"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {} // 纹理
        _BumpMap("Normal Map", 2D) = "bump" {} // 法线贴图
        _BumpScale("BumpScale", Range(0, 10)) = 1 // 法线贴图缩放； 用于控制 凹凸程度

        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)// 高光 
        _Gloss("Gloss", Range(1, 256)) = 1
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"// 包含光照计算函数

            sampler2D _MainTex;// 纹理
            float4 _MainTex_ST;// 是 _MainTex 的附属物 ，包含纹理的缩放和偏移

            sampler2D _BumpMap;// 法线贴图
            float4 _BumpMap_ST;// 是 _BumpMap 的附属物 ，包含纹理的缩放和偏移
            float _BumpScale;// 法线贴图缩放


            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct v2f
            {
                float4 vertex : SV_POSITION;// 顶点

                float4 uv : TEXCOORD0;//TEXCOORD2 语义:获取该模型纹理坐标 ； 用模型的 第三套 纹理坐标填充 TEXCOORD2； xy 储存 贴图 ； zw 存储法线贴图



                float4 TtoW0 : TEXCOORD1;// 切线转世界 矩阵
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            
            // 顶点着色器 
            // appdata_tan 是自定义的结构体，包含顶点位置、法线、切线、纹理坐标
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间

                // 让 外面的数值 可以影响到 uv
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;// 纹理坐标 ; https://www.lfzxb.top/unity-shader-base-texcoordn/
                // 替换上面
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);// 纹理坐标；也就是俗称的UV，是顶点数据的一部分； uv和有没有贴图没关系哦，uv是网格的属性

                // 法线贴图 ================
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);// 法线贴图 纹理坐标



                //世界坐标 顶点
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;// 世界坐标 顶点位置
                // 世界坐标 法线
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                // 世界切线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 世界坐标副切线
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 按列拜访到 世界 切线空间 的 变化矩阵
                // 切线 转 世界 空间的 矩阵; 本身 是 3x3  所以 第四列 应该是  0； 但是 为了节省寄存器 所以 将 worldPos 放到 最后一列
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // 世界坐标 顶点位置
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);// 世界坐标 顶点位置

                // 计算世界空间 下的 光照 和 视角
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //法线 =======

                // 法线贴图的采样
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从 _BumpMap 纹理中提取法向信息
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 


                // 将 法线 贴图设置成 normal map，不需要要 乘以 2，然后减去 1； 直接使用法线贴图的颜色值即可
                fixed3 tangentNormal = UnpackNormal(packedNormal);// UnpackNormal 解压 法线贴图
                tangentNormal.xy  *=  _BumpScale;


                // 切线空间 法线 转换成 世界空间
                fixed3 worldNormal = normalize(
                    float3 (
                        dot(i.TtoW0.xyz, tangentNormal),
                        dot(i.TtoW1.xyz, tangentNormal),
                        dot(i.TtoW2.xyz, tangentNormal)
                    )
                );



                // 法线 ======= end



                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;


                // 纹理图片采样 =========== 
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从_Bump纹理中提取法向信息
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 





                
                // fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(worldLightDir, i.worldNormal)) * 0.5 + 0.5);

                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(lightDir, worldNormal)) * 0.5 + 0.5);

                // 高光反射 ===========


                // 半角向量
                // fixed3 halfDir = normalize(worldLightDir + viewDir);// 光源向量 +  视角向量
                fixed3 halfDir = normalize(lightDir + viewDir);
              
                // 高光颜色
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

                fixed3 color = diffuse + ambient + specular;
                return fixed4 (color, 1);
            }
            ENDCG
        }
    }
}

// 计算法线
// 视角 光照方向 -> 切线空间

