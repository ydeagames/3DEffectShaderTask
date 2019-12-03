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

// うごめく画像
float4 movingTexture2(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float ran = perlinNoise(uv * 20);
	uv.x += (ran - 0.5f) * 0.1f * (3 - Time.x);
	float4 retUV = t.Sample(samLinear, uv);

	return retUV;
}

// うごめく画像
float4 movingTexture3(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float ran = perlinNoise(uv * 10);
	uv.x += (ran - 0.5f) * 0.1f * (5 - Time.x);
	float4 retUV = t.Sample(samLinear, uv);

	return retUV;
}

float distortion(float2 center, float r, float d_r, float2 tex)
{
	//中心から今のピクセルまでの距離
	float dist = distance(center, tex);
	//半径ｒのゆがみを作る幅はd_r
	//戻り値　歪みの値（歪みの偏差）
	return 1 - smoothstep(r - d_r, r, dist);
}

float4 portal(float2 center, float r, float d_r, float2 tx)
{
	//穴のゆがみ
	float d = distortion(center, r, d_r, tx);
	//画像のUV座標
	float2 uv = lerp(tx, center, d);
	//サンプリング画像(歪んだ画像（穴なし））
	float4 base = tex.Sample(samLinear, uv);
	//画像に穴をあける処理
	//戻り値　穴をあけた後の色情報
	return lerp(base, float4(0, 0, 0, 0), step(1, d));
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
	float4 retUV = distance(float2(uv.x * 800.f / 600.f + -200.f / 600.f / 2.f, uv.y), float2(.5f, .5f)) < .5f ? t.Sample(samLinear, uv) : float4(0, 0, 0, 0);
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
		bool p = (inUV.x < .5f);
		// xor = どちらか一方がtrueならtrue
		if ((b && !p) || (!b && p))
			return t.Sample(samLinear, inUV);
		return float4(0, 0, 0, 1);
	}
	else
	{
		float s = noise(inUV * 20);
		float4 color = float4(s, s, s, 1);
		if (s - Time.z < 0)
			return color;
		return float4(0, 0, 0, 0);
	}
}

// タスク
float4 taskB1(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	float4 diff = t.Sample(samLinear, uv);
	return diff;
}

// タスク
float4 taskB2(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	//float4 diff = t.Sample(samLinear,uv);
	float4 diff = blur(inUV);
	return diff;
}

// タスク
float4 taskB3(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	//float4 diff = t.Sample(samLinear,uv);
	float4 diff = movingTexture(t, inUV);
	return diff;
}

// タスク
float4 taskB4(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	uv.x /= 5.0f;
	uv.y /= 2.0f;

	uv.x += frac(3 / 5.0f);
	uv.y += floor(3 / 5.0f) / 2.0f;

	float4 diff = t.Sample(samLinear, uv);
	return diff;
}

// タスク
float4 taskB5(Texture2D t, float2 inUV)
{
	float4 diff = (float4)0;

	//float4 diff = t.Sample(samLinear,uv);
	float2 u = inUV;
	u.x += sin(Time.x - 5) * 0.05f;
	diff = t.Sample(samLinear, u);
	if (Time.x < 1.0f)
	{
		float time = 400 * Time.x;
		float2 uv = inUV;
		uv /= 5.0f;
		uv = floor(uv * time) / time;

		uv.x += 0.25f;
		uv.y += 0.25f;
		diff = t.Sample(samLinear, uv);
	}
	else if (Time.x < 2.0f)
	{
		float2 uv = inUV;
		uv /= 5.0f;
		uv.x += 0.25f;
		uv.y += 0.25f;
		diff = t.Sample(samLinear, uv);
	}
	else if (Time.x < 3.0f)
	{
		float2 uv = inUV;
		uv /= 3.0f;
		uv = floor(uv * 400 * (Time.x - 2)) / (400 * (Time.x - 2));
		uv.x += 0.5f;
		uv.y += 0.1f;
		diff = movingTexture2(t, uv);
	}
	else if (Time.x < 4.0f)
	{
		float2 uv = inUV;
		uv /= 3.0f;
		uv.x += 0.5f;
		uv.y += 0.1f;
		diff = t.Sample(samLinear, uv);
	}
	else if (Time.x < 5.0f)
	{
		float2 uv = inUV;
		diff = movingTexture3(t, uv);
	}

	return diff;
}

// テスト
float4 testB1(Texture2D t, float2 inUV)
{
	float tt = (sin(Time.x) + 1) / 2 + .1f;
	return portal(float2(.5f, .5f), .5f, tt, inUV);
}

// テスト
float4 testB2(Texture2D t, float2 inUV)
{
	float2 center = float2(.5f, .5f);
	float r = .4f;
	float d_r = .1f;

	float D1 = distortion(center, r, d_r, inUV);
	float4 P1 = portal(center, r, d_r, inUV);

	float2 center2 = float2(.3f, .7f);
	float r2 = .2f;
	float d_r2 = .1f;

	float D2 = distortion(center2, r2, d_r2, inUV);
	float4 P2 = portal(center2, r2, d_r2, inUV);

	return lerp(P1, P2, step(D1, D2));
}

// テスト
float4 testB3(Texture2D t, float2 inUV)
{
	float2 center = (float2)Mouse;
	float r = .4f;
	float d_r = .1f;

	float D1 = distortion(center, r, d_r, inUV);
	float4 P1 = portal(center, r, d_r, inUV);

	float2 center2 = float2(.3f, .7f);
	float r2 = .2f;
	float d_r2 = .1f;

	float D2 = distortion(center2, r2, d_r2, inUV);
	float4 P2 = portal(center2, r2, d_r2, inUV);

	float4 back = tex2.Sample(samLinear, inUV);

	if (Mouse.z > .1f)
	{
		back = float4(0, 0, 0, 1);
	}

	float4 L1 = lerp(P1, back, step(1, D1));
	float4 L2 = lerp(P2, back, step(1, D2));

	return lerp(L1, L2, step(D1, D2));
}

SamplerState MeshTextureSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

// テスト
float4 oldTV(Texture2D t, float2 inUV)
{
	float2 uv = inUV;

	uv -= .5f;

	float vignette = length(uv);

	uv /= 1 - vignette * .2f;

	if (max(abs(uv.y), abs(uv.x)) > .5f)
		return float4(0, 0, 0, 1);

	float2 texUV = uv + .5f;

	texUV.x += sin(texUV.y * 100) * .002f;

	texUV.x += (random(floor(texUV.y * 100) + Time.z) - .5f) * .01f;

	float4 base = t.Sample(samLinear, texUV);

	float3 col;
	col.r = t.Sample(samLinear, texUV).r; // col.r = base.r;
	col.g = t.Sample(samLinear, texUV + float2(.02f, 0)).g;
	col.b = t.Sample(samLinear, texUV + float2(.04f, 0)).b;

	if (random(floor(texUV.y * 500) + Time.z) < .001f)
	{
		col.r = random(uv + float2(123 + Time.z, 0));
		col.g = random(uv + float2(123 + Time.z, 1));
		col.b = random(uv + float2(123 + Time.z, 2));
	}

	col *= 1 - vignette * 1.3f;

	base = float4(col, base.a);

	return base;
}

float4 main(PS_INPUT input) : SV_TARGET
{
	//return testB3(tex, input.Tex);
	//return task7(tex, input.Tex);
	return oldTV(tex, input.Tex);
}
