#define PIx2 6.2831852
float items = 4;
float radius = 0.5;
float borderSoft = 0.01;

float4 AlphaComponent(float2 tex:TEXCOORD0,float4 color:COLOR0):COLOR0{
	tex *= items;
	color.rgb = floor(tex.x)%2 +floor(tex.y)%2 == 1;
	return color;
}


float4 Main(float2 tex:TEXCOORD0,float4 color:COLOR0):COLOR0{
	float nBorderSoft = borderSoft*sqrt(length(ddx(tex))*length(ddy(tex)))*100;
	float2 newTex = tex-0.5;
	float _radius = length(newTex);
	float angle = atan2(newTex.y,newTex.x)/PIx2;
	color.rgb = AlphaComponent(tex,color).rgb;
	color.a *= clamp(1-(_radius-radius+nBorderSoft)/nBorderSoft,0,1);
	return color;
}

technique RepTexture{
	pass P0{
		PixelShader = compile ps_2_a Main();
	}
}
