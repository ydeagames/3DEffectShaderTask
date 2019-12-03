#include "Particle.hlsli"
static const int vnum = 4;

static const float4 offset_array[vnum] =
{
	float4(-0.5f, -0.5f, 0, 0),	// ¶‰º
	float4(-0.5f, +0.5f, 0, 0),	// ¶ã
	float4(+0.5f, -0.5f, 0, 0),	// ‰Eã
	float4(+0.5f, +0.5f, 0, 0),	// ‰E‰º

};

[maxvertexcount(vnum)]
void main(
	point PS_INPUT input[1],
	inout TriangleStream< PS_INPUT > output
)
{
	for (uint i = 0; i < vnum; i++)
	{
		PS_INPUT element;

		element.Pos = input[0].Pos + offset_array[i]*2.0f;

		float4x4 rev = (float4x4)0;
		rev[0][0] = -1;
		rev[1][1] = 1;
		rev[2][2] = -1;
		rev[3][3] = 1;

		//rev *= matWorld;

		element.Pos = mul(element.Pos, matWorld);
		element.Pos = mul(element.Pos, matView);
		element.Pos = mul(element.Pos, matProj);

		element.Color = input[0].Color;
		
		element.Tex = offset_array[i];
		element.Tex.y *= -1;
		element.Tex += float2(0.5f,0.5f);
		element.Tex = element.Tex;
		output.Append(element);
	}
	output.RestartStrip();
}