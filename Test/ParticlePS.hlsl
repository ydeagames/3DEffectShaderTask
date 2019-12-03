#include "Particle.hlsli"


Texture2D tex : register(t0);
Texture2D tex2 : register(t1);
SamplerState samLinear : register(s0);

//乱数を作る処理
float random(float2 uv)
{
	//いい感じのランダムな数字（0～1)を返す
	//引数uvはUV(input.Texなど）を渡さないとランダムな値にならない
	return frac(sin(dot(uv, float2(12.9898f, 78.233f))) * 43758.5453f);
}

//ブロックノイズを作る処理
float noise(float2 uv)
{
	//渡すUVの値によってノイズの分割数が変わる(input.Tex * 20なら20分割など）
	float2 p = floor(uv);
	return random(p);
}

//ブラー
float4 blur(float2 uv)
{
	float b = 0.06f;		// blur
	float c = 1.0f - b * 8;	// center
	float4 dest = tex.Sample(samLinear, uv + float2(0.0f, 0.0f)) * c
		+ tex.Sample(samLinear, uv + float2(-0.01f, -0.01f)) * b
		+ tex.Sample(samLinear, uv + float2(-0.01f, 0.0f)) * b
		+ tex.Sample(samLinear, uv + float2(-0.01f, 0.01f)) * b
		+ tex.Sample(samLinear, uv + float2(0.0f, -0.01f)) * b
		+ tex.Sample(samLinear, uv + float2(0.0f, 0.01f)) * b
		+ tex.Sample(samLinear, uv + float2(0.01f, -0.01f)) * b
		+ tex.Sample(samLinear, uv + float2(0.01f, 0.0f)) * b
		+ tex.Sample(samLinear, uv + float2(0.01f, 0.01f)) * b;
	return dest;
}

//モザイク
float2 mosaic(float2 baseUV, float mag)
{
	return floor(baseUV * mag) / mag;
}

//乱数を作る処理(float2 ver)
//＋１～－１の範囲でx,yそれぞれ乱数を返す
float2 random2(float2 uv)
{
	float2 r = float2(dot(uv, float2(127.1f, 311.7f)),
		dot(uv, float2(269.5f, 183.3f)));
	return -1.0 + 2.0f * frac(sin(r) * 43758.5453123f);
}

//パーリンノイズを生成する関数
float perlinNoise(float2 uv)
{
	float2 p = floor(uv);
	float2 f = frac(uv);
	float2 u = f * f * (3.0f - 2.0f * f);
	float v00 = random2(p + float2(0, 0)).x;
	float v10 = random2(p + float2(1, 0)).x;
	float v01 = random2(p + float2(0, 1)).x;
	float v11 = random2(p + float2(1, 1)).x;
	return lerp(lerp(dot(v00, f - float2(0, 0)), dot(v10, f - float2(1, 0)), u.x),
		lerp(dot(v01, f - float2(0, 1)), dot(v11, f - float2(1, 1)), u.x),
		u.y) + 0.5f;
}

//非整数ブラウン運動を作る処理
//Fractional Brownian Motion
float fBm(float2 uv)
{
	float f = 0;
	float2 q = uv;
	//正式な式は3行目も実行されるが、処理負荷が高くなるのでコメントアウト
	f += 0.5000f * perlinNoise(q); q = q * 2.01f;
	f += 0.2500f * perlinNoise(q); q = q * 2.02f;
	//f += 0.1250f*perlinNoise(q); q = q * 2.03f;
	f += 0.0625f * perlinNoise(q); q = q * 2.01f;
	return f;
}

// うごめく画像
float4 movingTexture(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float ran = perlinNoise(uv * 20);
	uv.x += (ran - 0.5f) * 0.1f * (2 - Time.z);
	float4 retUV = t.Sample(samLinear, uv);
	return retUV;
}

// タスク
float4 task1(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = t.Sample(samLinear, uv);
	return retUV;
}

// タスク
float4 task2(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = inUV.x > .5f ? t.Sample(samLinear, uv) : float4(0, 0, 0, 0);
	return retUV;
}

// タスク
float4 task3(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = distance(float2(uv.x * 800.f / 600.f + -200.f/600.f/2.f, uv.y), float2(.5f, .5f)) < .5f ? t.Sample(samLinear, uv) : float4(0, 0, 0, 0);
	return retUV;
}

// タスク
float4 task4(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 color = t.Sample(samLinear, uv);
	float s = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
	color = float4(s, s, s, 1);
	return color;
}

// タスク
float4 task5(Texture2D t, float2 inUV)
{
	float s = noise(inUV * 4);
	float4 color = float4(s, s, s, 1);
	return color;
}

// タスク
float4 task6(Texture2D t, float2 inUV)
{
	float s = perlinNoise(inUV * 4);
	if (s - Time.z < 0)
		return t.Sample(samLinear, inUV);
	return float4(0, 0, 0, 0);
}

// タスク
float4 task7(Texture2D t, float2 inUV)
{
	if (distance(float2(inUV.x * 800.f / 600.f + -200.f / 600.f / 2.f, inUV.y), float2(.5f, .5f)) > .25f)
	{
		float s = perlinNoise(inUV * 4);
		bool b = (s - Time.z < 0);
		bool p = (inUV < .5f);
		if ((b && !p) || (!b && p))
			return t.Sample(samLinear, inUV);
		return float4(0, 0, 0, 1);
	}
	else
	{
		float s = noise(inUV * 20);
		float4 color = float4(s, s, s, 1);
		if (color.r - Time.z < 0)
			return color;
		return float4(0, 0, 0, 0);
	}
}

float4 main(PS_INPUT input) : SV_TARGET
{
	return task7(tex, input.Tex);
}
