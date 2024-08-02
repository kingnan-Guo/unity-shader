Shader "Unlit/shadowTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
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

        // Pass{
        //     Tags{ "LightMode" = "ShadowCaster" }
        //     CGPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag

        //     #pragma multi_compile_shadowcaster

        //     #include "AutoLight.cginc"
        //     #include "UnityCG.cginc"
        // }
        // 阴影投射
        Pass
        {
            //1、设置 "LightMode" = "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            //需要添加一个 Unity变体
            #pragma multi_compile_shadowcaster

            
            #include "UnityCG.cginc"

            //声明消融使用的变量
            float _Clip;
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            
            //2、appdata中声明float4 vertex:POSITION;和half3 normal:NORMAL;这是生成阴影所需要的语义.
            //注意：在appdata部分，我们几乎不要去修改名字 和 对应的类型。
            //因为，在Unity中封装好的很多方法都是使用这些标准的名字
            struct appdata
            {
                float4 vertex:POSITION;
                half3 normal:NORMAL;
                float4 uv:TEXCOORD;
            };
            //3、v2f中添加V2F_SHADOW_CASTER;用于声明需要传送到片断的数据.
            struct v2f
            {
                float4 uv : TEXCOORD;
                V2F_SHADOW_CASTER;
            };
            //4、在顶点着色器中添加TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)，主要是计算阴影的偏移以解决不正确的Shadow Acne和Peter Panning现象.
            v2f vert(appdata v)
            {
                v2f o;
                o.uv.zw = TRANSFORM_TEX(v.uv,_DissolveTex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }
            //5、在片断着色器中添加SHADOW_CASTER_FRAGMENT(i)
            
            fixed4 frag(v2f i) : SV_Target
            {
                //外部获取的 纹理 ，使用前都需要采样
                fixed4 dissolveTex = tex2D(_DissolveTex,i.uv.zw);
                
                //片段的取舍
                clip(dissolveTex.r -  _Clip);
                
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }


    }
    Fallback "Diffuse"
    // Fallback ""
}
