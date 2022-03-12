#define PI 3.1415926
#define PI2 PI*2
float borderSoft = 0.01;
float angle = 2*PI;
float outsideRadius = 0.5;
float insideRadius = 0;
float textureRot = 0;
float2 textureRotCenter = float2(0.5,0.5);
texture sourceTexture;
bool direction = true; //anticlockwise
bool colorOverwritten = true;

SamplerState tSampler{
	Texture = sourceTexture;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};
float items = 4;
bool vertical = false;

float4 AlphaComponent(float2 otex:TEXCOORD0,float4 color:COLOR0):COLOR0{
	float dxdy = ddx(otex.x)/ddy(otex.y);
	float2 ddxddy = float2(dxdy,1/dxdy);
	float _x = otex[vertical];
	float _y = otex[!vertical];
	float2 tex = float2(_x,_y);
	tex *= items;
	tex.y *= ddxddy[vertical];
	color.rgb = floor(tex.x)%2 +floor(tex.y)%2 == 1;
	return color;
}

float4 Main(float2 tex:TEXCOORD0,float4 color:COLOR0):COLOR0{
	float thetaCos = cos(-textureRot/180.0*PI);
	float thetaSin = sin(-textureRot/180.0*PI);
	float2x2 rot = float4(thetaCos,-thetaSin,thetaSin,thetaCos);
	float2 rotedTex = mul(tex-textureRotCenter,rot)+textureRotCenter;
	float4 result = AlphaComponent(tex,color);
	float2 dxy = float2(length(ddx(tex)),length(ddy(tex)));
	float nBorderSoft = borderSoft*sqrt(dxy.x*dxy.y)*100;
	float xDistance = tex.x-0.5,yDistance = 0.5-tex.y;
	float angle_p = atan2(yDistance,xDistance);	//angle_p
	if(angle_p>PI2) angle_p -= PI2;
	if(angle_p<0) angle_p += PI2;
	float2 P = float2(xDistance,yDistance);
	float ang = angle;
	if(!direction){
		ang = PI2-angle;
	}
	float2 Q = float2(cos(ang),sin(ang));
	float2 N = float2(-Q.y,Q.x)*nBorderSoft;
	float oRadius = 1-outsideRadius;
	Q *= oRadius;
	float2 Start = float2(oRadius,0);
	float2 StartN = float2(-Start.y,Start.x);
	float alpha = !direction;
	if(angle_p<ang) alpha = direction;
	if(direction){
		float2 P1 = P-N;
		float len0P = length(P1);
		float len0Q = length(Q);
		float lenPQ = distance(P1,Q);
		float a = dot(Q,P1)/(len0Q*len0P);
		float halfC1 = 0.5*(len0P+len0Q+lenPQ);
		float dis1 = 2*sqrt(halfC1*(halfC1-len0P)*(halfC1-len0Q)*(halfC1-lenPQ))/len0Q;
		float _a = dot(N,P1)/(nBorderSoft*len0P);
		P.y += nBorderSoft;
		len0P = length(P);
		float len0S = oRadius;
		float lenPS = distance(P,Start);
		float b = dot(Start,P)/(len0S*len0P);
		float halfC2 = 0.5*(len0P+len0S+lenPS);
		float dis2 = 2*sqrt(halfC2*(halfC2-len0P)*(halfC2-len0S)*(halfC2-lenPS))/len0S;
		float _b = dot(StartN,P)/(length(StartN)*len0P);
		bool hit1 = (a >= 0 && dis1 < nBorderSoft && _a<=0);
		bool hit2 = (b >= 0 && dis2 < nBorderSoft && _b>=0);
		if(hit1&&hit2)
			alpha += max(clamp((dis1)/nBorderSoft,0,1),clamp((dis2)/nBorderSoft,0,1));
		else if(hit1)
			alpha += clamp((dis1)/nBorderSoft,0,1);
		else if(hit2)
			alpha += clamp((dis2)/nBorderSoft,0,1);
	}else{
		float2 P1 = P+N;
		float len0P = length(P1);
		float len0Q = length(Q);
		float lenPQ = distance(P1,Q);
		float a = dot(Q,P1)/(len0Q*len0P);
		float halfC1 = 0.5*(len0P+len0Q+lenPQ);
		float dis1 = 2*sqrt(halfC1*(halfC1-len0P)*(halfC1-len0Q)*(halfC1-lenPQ))/len0Q;
		float _a = dot(N,P1)/(nBorderSoft*len0P);
		P.y -= nBorderSoft;
		len0P = length(P);
		float len0S = oRadius;
		float lenPS = distance(P,Start);
		float b = dot(Start,P)/(len0S*len0P);
		float halfC2 = 0.5*(len0P+len0S+lenPS);
		float dis2 = 2*sqrt(halfC2*(halfC2-len0P)*(halfC2-len0S)*(halfC2-lenPS))/len0S;
		float _b = dot(StartN,P)/(length(StartN)*len0P);
		bool hit1 = (a >= 0 && dis1 < nBorderSoft && _a>=0);
		bool hit2 = (b >= 0 && dis2 < nBorderSoft && _b<=0);
		if(hit1&&hit2){
			alpha += max(clamp((dis1)/nBorderSoft,0,1),clamp((dis2)/nBorderSoft,0,1));
		}else if(hit1)
			alpha += clamp((dis1)/nBorderSoft,0,1);
		else if(hit2)
			alpha += clamp((dis2)/nBorderSoft,0,1);
	}
	alpha *= clamp((1-distance(tex,0.5)-oRadius+nBorderSoft)/nBorderSoft,0,1);
	alpha *= clamp((distance(tex,0.5)-insideRadius+nBorderSoft)/nBorderSoft,0,1);
	result.a *= clamp(alpha,0,1)*color.a;
	result.rgb = colorOverwritten?result.rgb:color.rgb;
	return result;
}

technique RepTexture{
	pass P0{
		PixelShader = compile ps_2_a Main();
	}
}