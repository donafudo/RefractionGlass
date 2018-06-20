Shader "Custom/GlassSurface1"
{
	Properties
	{
		_BumpMap("NormalMap",2D) = "bump" {}
		_GlassColor("GlassColor", Color) = (0,0,0,0)
		[Header(RimLight)]
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimWeight("RimWeight",Float) = 0.5
		[Header(Material)]
		_Rrefractive("Refractive", Range(0,1)) = 0.1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		[Space(20)]
		[IntRange]_Stencil("Stencil", Range(0,255)) = 10
	}

	SubShader
	{
		Tags
		{ 
			"Queue" ="Transparent" 
			 "RenderType" = "Transparent"
		}

		GrabPass{"_GrabBackTexture1"}

		Pass
		{
			Cull Front

			Stencil{
			Ref [_Stencil]
			Comp Always
			Pass Replace
}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD1;
			};

			sampler2D _BumpMap;

			float _Rrefractive;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = UnityObjectToWorldNormal(v.normal);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 normal = UnpackNormal(tex2D(_BumpMap ,i.uv));
				normal = mul(UNITY_MATRIX_V, normal);
				return float4(i.normal - normal, 1);
			}
			ENDCG
		}

		GrabPass{}

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows


		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _GrabBackTexture1;
		sampler2D _GrabTexture;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float4 screenPos;
			float3 worldNormal;
			float3 viewDir;
			INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;

		fixed4 _GlassColor;
		fixed4 _RimColor;
		float _RimWeight;
		float _Rrefractive;

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			float3 rimdir = pow(1 - saturate(dot(IN.viewDir, o.Normal)),3);

			float2 grabUV = (IN.screenPos.xy / IN.screenPos.w);

			float3 forwardnormal = WorldNormalVector(IN, o.Normal);
			forwardnormal = mul(UNITY_MATRIX_V, forwardnormal);
			fixed3 normalmap = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			fixed3 backnormal = tex2D(_GrabTexture, grabUV);
			fixed3 normal = (forwardnormal + backnormal + normalmap);
			
			grabUV += normal*_Rrefractive;

			fixed4 grab = tex2D(_GrabBackTexture1, grabUV)*_GlassColor;

			float3 rim = saturate(rimdir*_RimColor*_RimWeight);

			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
			o.Albedo = saturate(grab.rgb + rim);
			o.Normal = normal;

		}
		ENDCG

		Stencil{
			Ref[_Stencil]
			Comp NotEqual
			Pass Keep
		}

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _GrabBackTexture;
		sampler2D _GrabNormalTexture;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float4 screenPos;
			float3 viewDir;
			INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;

		fixed4 _GlassColor;
		fixed4 _RimColor;
		float _RimWeight;
		float _Rrefractive;

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			float3 rimdir = pow(1 - saturate(dot(IN.viewDir, o.Normal)), 3);

			float2 grabUV = (IN.screenPos.xy / IN.screenPos.w);

			fixed3 normalmap = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			fixed3 normal = (normalmap);

			grabUV += normal*_Rrefractive;

			fixed4 grab = tex2D(_GrabBackTexture, grabUV)*_GlassColor;

			fixed3 rim = saturate(rimdir*_RimColor*_RimWeight);

			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
			o.Albedo = saturate(grab.rgb + rim);
			o.Normal = normal;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
