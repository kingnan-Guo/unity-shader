Shader "Unlit/textureSampling"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {} // 纹理
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

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

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
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;// 采样之后的值要乘到 漫反射 里， 因为属于 M 物体的材质 


                // 漫反射 ==============
                // 光源方向
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);// _WorldSpaceLightPos0 世界光源方向; 归一化
                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPosition);


                fixed3 worldNormal = normalize(i.worldNormal);// 归一化

                // fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * (max(0, dot(worldLightDir, i.worldNormal)) * 0.5 + 0.5);


                // 高光反射
                fixed3 reflectDir = normalize(reflect(-worldLightDir, i.worldNormal));
                

                // 视角方向
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPosition));


                // 半角向量
                fixed3 halfDir = normalize(worldLightDir + viewDir);// 光源向量 +  视角向量
              
                // 高光颜色
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfDir)), _Gloss);



                fixed3 color = diffuse + ambient + specular;
                return fixed4 (color, 1);
            }
            ENDCG
        }
    }
}


// TEXCOORD到底是个什么东西

// 我们来看看官方文档怎么说

// TEXCOORD0 is the first UV coordinate, typically float2, float3 or float4.
// TEXCOORD1, TEXCOORD2 and TEXCOORD3 are the 2nd, 3rd and 4th UV coordinates, respectively.
// 看上去很简单，TEXCOORD是指纹理坐标，float2, float3, float4类型。n是指第几组纹理坐标。

// 第几组？？？能有几组uv？？？
// 身为对美术一无所知的逻辑仔，我是不太明白的，在网上也没有找到好的答案，好在咨询了很多大佬，在此整理一下。

// 模型中每个顶点保存有uv，可能有一套或者几套，这些uv是指三维模型在2D平面的展开，跟纹理对应上进行插值采样就看到三维里的纹理颜色了
// https://kumokyaku.github.io/2019/07/14/UNITY%E7%94%9F%E6%88%90LightmapUVs/
// 这张Blender的图很好展示了多套纹理坐标到底是个什么东西（来自上面的链接）

// 简单来说texcoord就是存在顶点里的一组数据，我们可以通过这组数据在渲染的时候进行贴图采样，比如我们常用的第一套uv作为基础纹理，通常基础纹理我们可以根据需求进行一些区域的uv重用（比如左右脸贴图一样，可以映射到统一贴图区域），第二套uv经常用于光照贴图，光照贴图要求是uv不可以重复，所以通常不能用第一套uv，第三套uv用于更加奇特的需求，以此类推。。。
// texcoord应该是更加标准的名称，不过因为这个坐标系里面用uvw作为三个轴名称，所以美术那边普遍称作uv