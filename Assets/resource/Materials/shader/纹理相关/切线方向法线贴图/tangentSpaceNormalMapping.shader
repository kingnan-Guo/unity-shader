Shader "Unlit/tangentSpaceNormalMapping"
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
                // fixed3 worldNormal : TEXCOORD0;// 法线 不需要了
                fixed3 lightDir : TEXCOORD0;// 光源 方向
                
                // float3 worldPosition : TEXCOORD1;// 世界顶点位置 不需要了
                fixed3 viewDir : TEXCOORD1;// 视角方向

                float2 uv : TEXCOORD2;//TEXCOORD2 语义:获取该模型纹理坐标 ； 用模型的 第三套 纹理坐标填充 TEXCOORD2

                float2 nomalUV : TEXCOORD3;// 法线贴图的UV
            };

            
            // 顶点着色器 
            // appdata_tan 是自定义的结构体，包含顶点位置、法线、切线、纹理坐标
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);// 将顶点从模型空间转换到裁剪空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);// 法线向量 （模型空间）； 法线的转换不是 正常 mvp（物体坐标转换空间坐标） 的转换方式; 
                // o.worldNormal = worldNormal; 不需要了
                // o.worldPosition = UnityObjectToWorldDir(v.vertex);// 顶点位置 （世界 空间）
                // o.worldPosition = mul(unity_ObjectToWorld, v.vertex); 不需要了

                // 让 外面的数值 可以影响到 uv
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;// 纹理坐标 ; https://www.lfzxb.top/unity-shader-base-texcoordn/
                // 替换上面
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);// 纹理坐标；也就是俗称的UV，是顶点数据的一部分； uv和有没有贴图没关系哦，uv是网格的属性


                // 法线贴图 ================
                o.nomalUV = TRANSFORM_TEX(v.texcoord, _BumpMap);// 法线贴图 纹理坐标
                // 需要把视角 光照方向 转换成 切线空间 
                // 所以 要计算出 转换切线空间的矩阵

                // // 1、求副切线向量 
                // // cross 叉乘; v.tangent.w 切线方向 v.tangent.w是副切线的方向，因为副切线有两种相反的方向； v.normal 是模型空间的法线； v.tangent.xyz 是模型空间的切线
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;// 副切线向量
                // // 2、旋转 矩阵，因为只做了旋转； 使用 rotation 矩阵，把世界空间的光照方向 转换成 切线空间
                // float3x3 rotation = float3x3(normalize(v.tangent.xyz), binormal, normalize(v.normal));

                // 使用 TANGENT_SPACE_ROTATION 矩阵，把世界空间的光照方向 转换成 切线空间; 可以替换上面的 1、2; ; 这个是Unity的内置宏，在UnityCG.cginc中被定义 
                TANGENT_SPACE_ROTATION;
                
                // 求切线空间视角及 光源方向 
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;// ObjSpaceLightDir 将光照转换成模型空间； 再乘以 旋转矩阵转到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz; // ObjSpaceViewDir 将视角转换成模型空间； 再乘以 旋转矩阵转到切线空间

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                //法线 =======
                // 切线空间的 光源 方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                // 切线空间的 视角方向
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 法线贴图的采样
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从 _BumpMap 纹理中提取法向信息
                fixed4 packedNormal = tex2D(_BumpMap, i.nomalUV);// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 

                // //  没有将 法线 贴图设置成 normal map （法线贴图），所以法线贴图的颜色值需要乘以 2，然后减去 1，才能得到正确的法线方向
                // // 颜色要从 （-1， 1）转换为 （0， 1）之间
                // // packedNormal = packedNormal * 2 - 1;
                // fixed3 tangentNormal;// 切线空间的 法线 方向
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) *  _BumpScale;

                // // 因为 法线向量 是 单位向量，
                // // x^2 +y^2 + z^2 = 1;
                // // 所以 z = sqrt(1 - x^2 - y^2);
                // // x^2 +y^2  = dot(tangentNormal.xy, tangentNormal.xy); saturate限制 大于 0
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 将 法线 贴图设置成 normal map，不需要要 乘以 2，然后减去 1； 直接使用法线贴图的颜色值即可
                fixed3 tangentNormal = UnpackNormal(packedNormal);// UnpackNormal 解压 法线贴图
                tangentNormal.xy  *=  _BumpScale;
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); // UnpackNormal 中包含了 这一步 所以 注掉

                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy))); 可加可不加

                // 法线 ======= end



                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;


                // 纹理图片采样 =========== 
                // tex2D 根据uv坐标（float2）获取纹理（sampler2D）上对应位置的颜色值
                // tex2D(_Bump, IN.uv_Bump) 从_Bump纹理中提取法向信息
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 


                // 漫反射 ==============
                // 光源方向
                // fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPosition); 不用了


                // fixed3 worldNormal = normalize(i.worldNormal);// 归一化 不用了


                
                // fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(worldLightDir, i.worldNormal)) * 0.5 + 0.5);
                // worldLightDir 替换成 切线空间下的 光源 向量 tangentLightDir
                // i.worldNormal 替换成 切线空间下的 法线 向量 tangentNormal
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(tangentLightDir, tangentNormal)) * 0.5 + 0.5);

                // 高光反射 ===========
                // fixed3 reflectDir = normalize(reflect(-worldLightDir, i.worldNormal)); 不用了
                

                // 视角方向
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                // fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition)); 不用了


                // 半角向量
                // fixed3 halfDir = normalize(worldLightDir + viewDir);// 光源向量 +  视角向量
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
              
                // 高光颜色
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);



                fixed3 color = diffuse + ambient + specular;
                return fixed4 (color, 1);
            }
            ENDCG
        }
    }
}

// 计算法线
// 视角 光照方向 -> 切线空间
