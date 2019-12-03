#include "Particle.hlsli"


Texture2D tex : register(t0);
Texture2D tex2 : register(t1);
SamplerState samLinear : register(s0);

//��������鏈��
float random(float2 uv)
{
	//���������̃����_���Ȑ����i0�`1)��Ԃ�
	//����uv��UV(input.Tex�Ȃǁj��n���Ȃ��ƃ����_���Ȓl�ɂȂ�Ȃ�
	return frac(sin(dot(uv, float2(12.9898f, 78.233f))) * 43758.5453f);
}

//�u���b�N�m�C�Y����鏈��
float noise(float2 uv)
{
	//�n��UV�̒l�ɂ���ăm�C�Y�̕��������ς��(input.Tex * 20�Ȃ�20�����Ȃǁj
	float2 p = floor(uv);
	return random(p);
}

//�u���[
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

//���U�C�N
float2 mosaic(float2 baseUV, float mag)
{
	return floor(baseUV * mag) / mag;
}

//��������鏈��(float2 ver)
//�{�P�`�|�P�͈̔͂�x,y���ꂼ�ꗐ����Ԃ�
float2 random2(float2 uv)
{
	float2 r = float2(dot(uv, float2(127.1f, 311.7f)),
		dot(uv, float2(269.5f, 183.3f)));
	return -1.0 + 2.0f * frac(sin(r) * 43758.5453123f);
}

//�p�[�����m�C�Y�𐶐�����֐�
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

//�񐮐��u���E���^������鏈��
//Fractional Brownian Motion
float fBm(float2 uv)
{
	float f = 0;
	float2 q = uv;
	//�����Ȏ���3�s�ڂ����s����邪�A�������ׂ������Ȃ�̂ŃR�����g�A�E�g
	f += 0.5000f * perlinNoise(q); q = q * 2.01f;
	f += 0.2500f * perlinNoise(q); q = q * 2.02f;
	//f += 0.1250f*perlinNoise(q); q = q * 2.03f;
	f += 0.0625f * perlinNoise(q); q = q * 2.01f;
	return f;
}

// �����߂��摜
float4 movingTexture(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float ran = perlinNoise(uv * 20);
	uv.x += (ran - 0.5f) * 0.1f * (2 - Time.z);
	float4 retUV = t.Sample(samLinear, uv);
	return retUV;
}

// �����߂��摜
float4 movingTexture2(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float ran = perlinNoise(uv * 20);
	uv.x += (ran - 0.5f) * 0.1f * (3 - Time.x);
	float4 retUV = t.Sample(samLinear, uv);

	return retUV;
}

// �����߂��摜
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
	//���S���獡�̃s�N�Z���܂ł̋���
	float dist = distance(center, tex);
	//���a���̂䂪�݂���镝��d_r
	//�߂�l�@�c�݂̒l�i�c�݂̕΍��j
	return 1 - smoothstep(r - d_r, r, dist);
}

float4 portal(float2 center, float r, float d_r, float2 tx)
{
	//���̂䂪��
	float d = distortion(center, r, d_r, tx);
	//�摜��UV���W
	float2 uv = lerp(tx, center, d);
	//�T���v�����O�摜(�c�񂾉摜�i���Ȃ��j�j
	float4 base = tex.Sample(samLinear, uv);
	//�摜�Ɍ��������鏈��
	//�߂�l�@������������̐F���
	return lerp(base, float4(0, 0, 0, 0), step(1, d));
}

// �^�X�N
float4 task1(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = t.Sample(samLinear, uv);
	return retUV;
}

// �^�X�N
float4 task2(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = inUV.x > .5f ? t.Sample(samLinear, uv) : float4(0, 0, 0, 0);
	return retUV;
}

// �^�X�N
float4 task3(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 retUV = distance(float2(uv.x * 800.f / 600.f + -200.f / 600.f / 2.f, uv.y), float2(.5f, .5f)) < .5f ? t.Sample(samLinear, uv) : float4(0, 0, 0, 0);
	return retUV;
}

// �^�X�N
float4 task4(Texture2D t, float2 inUV)
{
	float2 uv = inUV;
	float4 color = t.Sample(samLinear, uv);
	float s = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
	color = float4(s, s, s, 1);
	return color;
}

// �^�X�N
float4 task5(Texture2D t, float2 inUV)
{
	float s = noise(inUV * 4);
	float4 color = float4(s, s, s, 1);
	return color;
}

// �^�X�N
float4 task6(Texture2D t, float2 inUV)
{
	float s = perlinNoise(inUV * 4);
	if (s - Time.z < 0)
		return t.Sample(samLinear, inUV);
	return float4(0, 0, 0, 0);
}

// �^�X�N
float4 task7(Texture2D t, float2 inUV)
{
	if (distance(float2(inUV.x * 800.f / 600.f + -200.f / 600.f / 2.f, inUV.y), float2(.5f, .5f)) > .25f)
	{
		float s = perlinNoise(inUV * 4);
		bool b = (s - Time.z < 0);
		bool p = (inUV.x < .5f);
		// xor = �ǂ��炩�����true�Ȃ�true
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

// �^�X�N
float4 taskB1(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	float4 diff = t.Sample(samLinear, uv);
	return diff;
}

// �^�X�N
float4 taskB2(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	//float4 diff = t.Sample(samLinear,uv);
	float4 diff = blur(inUV);
	return diff;
}

// �^�X�N
float4 taskB3(Texture2D t, float2 inUV)
{
	float2 uv = floor(inUV * 20.0f) / 20.0f;
	//float4 diff = t.Sample(samLinear,uv);
	float4 diff = movingTexture(t, inUV);
	return diff;
}

// �^�X�N
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

// �^�X�N
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

// �e�X�g
float4 testB1Custom(Texture2D t, float2 inUV, float2 c1, float2 p1)
{
	return portal(c1, p1.x, p1.y, inUV);
}

// �e�X�g
float4 testB1(Texture2D t, float2 inUV)
{
	float tt = (sin(Time.x) + 1) / 2 + .1f;
	return testB1Custom(t, inUV, float2(.5f, .5f), float2(.5f, tt));
}

// �e�X�g
float4 testB2Custom(Texture2D t, float2 inUV, float2 c1, float2 c2, float2 p1, float2 p2)
{
	float D1 = distortion(c1, p1.x, p1.y, inUV);
	float4 P1 = portal(c1, p1.x, p1.y, inUV);

	float D2 = distortion(c2, p2.x, p2.y, inUV);
	float4 P2 = portal(c2, p2.x, p2.y, inUV);

	return lerp(P1, P2, step(D1, D2));
}

// �e�X�g
float4 testB2(Texture2D t, float2 inUV)
{
	return testB2Custom(t, inUV, float2(.5f, .5f), float2(.3f, .7f), float2(.4f, .1f), float2(.2f, .1f));
}

// �e�X�g
float4 testB3Custom(Texture2D t, float2 inUV, float2 c1, float2 c2, float2 p1, float2 p2, bool mouseEnable = false)
{
	float D1 = distortion(c1, p1.x, p1.y, inUV);
	float4 P1 = portal(c1, p1.x, p1.y, inUV);

	float D2 = distortion(c2, p2.x, p2.y, inUV);
	float4 P2 = portal(c2, p2.x, p2.y, inUV);

	float4 back = tex2.Sample(samLinear, inUV);

	if (mouseEnable && Mouse.z > .1f)
	{
		back = float4(0, 0, 0, 0);
	}

	float4 L1 = lerp(P1, back, step(1, D1));
	float4 L2 = lerp(P2, back, step(1, D2));

	return lerp(L1, L2, step(D1, D2));
}

// �e�X�g
float4 testB3(Texture2D t, float2 inUV)
{
	return testB3Custom(t, inUV, (float2)Mouse, float2(.3f, .7f), float2(.4f, .1f), float2(.2f, .1f));
}

SamplerState MeshTextureSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

// �e�X�g
float4 oldTV(Texture2D t, float2 inUV, bool useMouse = false)
{
	float2 uv = inUV;

	uv -= .5f;

	float vignette = length(uv);

	uv /= 1 - vignette * .2f;

	if (max(abs(uv.y), abs(uv.x)) > .5f)
		return float4(0, 0, 0, 1);

	float2 texUV = uv + .5f;
	float2 pUV = uv + .5f;

	texUV.x += sin(texUV.y * 100) * .002f;

	texUV.x += (random(floor(texUV.y * 100) + Time.z) - .5f) * .01f;

	float4 base;
	float3 col;
	if (!useMouse)
	{
		base = t.Sample(samLinear, texUV);

		col.r = t.Sample(samLinear, texUV).r; // col.r = base.r;
		col.g = t.Sample(samLinear, texUV + float2(.02f, 0)).g;
		col.b = t.Sample(samLinear, texUV + float2(.04f, 0)).b;
	}
	else
	{
		float size = (1 + Time.z) / 4.0f;
		base = portal((float2)Mouse, size.x, size.x / 2.0f, pUV);

		col.r = portal((float2)Mouse, size.x, size.x / 2.0f, pUV).r;
		col.g = portal((float2)Mouse, size.x, size.x / 2.0f, pUV + float2(0.002f, 0)).g;
		col.b = portal((float2)Mouse, size.x, size.x / 2.0f, pUV + float2(0.004f, 0)).b;
	}

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

// �^�X�N
float4 taskC1(Texture2D t, float2 inUV)
{
	return testB1Custom(t, inUV, float2(0.5f, 0.5f), float2(0.3f, 0.1f));
}

// �^�X�N
float4 taskC2(Texture2D t, float2 inUV)
{
	return testB3Custom(t, inUV, float2(0.5f, 0.5f), float2(0.5f, 0.5f), float2(0.3f, 0.1f), float2(0.3f, 0.1f));
}

// �^�X�N
float4 taskC3(Texture2D t, float2 inUV)
{
	return testB2Custom(t, inUV, float2(.5f, .5f), float2(.3f, .7f), float2(.3f, .1f), float2(.3f, .1f));
}

// �^�X�N
float4 taskC4(Texture2D t, float2 inUV)
{
	return testB3Custom(t, inUV, float2(.5f, .5f), float2(.2f, .4f), float2(.3f, .1f), float2(.5f, .05f));
}

// �^�X�N
float4 taskC5(Texture2D t, float2 inUV)
{
	return testB3Custom(t, inUV, (float2)Mouse, float2(.2f, .4f), float2(.3f, .1f), float2(.3f, .05f));
}

// �^�X�N
float4 taskC6(Texture2D t, float2 inUV)
{
	return testB3Custom(t, inUV, (float2)Mouse, float2(.2f, .4f), float2(.3f, .1f), float2(.3f, .05f), true);
}

// �^�X�N
float4 taskC7(Texture2D t, float2 inUV)
{
	return oldTV(t, inUV);
}

// �^�X�N
float4 taskC8(Texture2D t, float2 inUV)
{
	float4 tv = oldTV(t, inUV, true);

	if (tv.a < 0.5f)
	{
		if (!Mouse.z)
			tv = float4(0, 0, 0, 1);
		else
			tv = tex2.Sample(samLinear, inUV);
	}

	return tv;
}

float4 main(PS_INPUT input) : SV_TARGET
{
	//return testB3(tex, input.Tex);
	return taskC8(tex, input.Tex);
	//return oldTV(tex, input.Tex);
}
