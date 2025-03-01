// ����ȫ�ֳ���������
cbuffer $Globals
{
    row_major float4x4 mW2P;           // Offset:    0 Size:    64
    float4 mL2WT[3];                   // Offset:   64 Size:    48
    float4 mL2W[6];                    // Offset:  112 Size:    96
    row_major float4x4 vmPrevW2P;      // Offset:  208 Size:    64
};

// ���嶥������ṹ��
struct VS_INPUT
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float4 tangent : TANGENT;
};

// ���嶥������ṹ��
struct VS_OUTPUT
{
    float4 position : SV_POSITION;
    float4 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float3 texcoord3 : TEXCOORD3;
    float3 texcoord4 : TEXCOORD4;
    float2 texcoord5 : TEXCOORD5;
};

// ������ɫ������
VS_OUTPUT main(VS_INPUT input)
{
    VS_OUTPUT output;

    // �����м��� r0
    float r0_y = dot(input.position, mL2W[1]);
    float r0_x = dot(input.position, mL2W[0]);
    float r0_z = dot(input.position, mL2W[2]);

    // ���� r1
    float4 r1 = r0_y * mW2P[1];
    r1 = r0_x * mW2P[0] + r1;
    r1 = r0_z * mW2P[2] + r1;

    // ���� o2 �� xyz ����
    output.texcoord1.xyz = float3(r0_x, r0_y, r0_z);

    // �������յĲü��ռ�λ��
    float4 clipPos = input.position.w * mW2P[3] + r1;

    // ���������λ�ú� texcoord0
    output.position = clipPos;
    output.texcoord0 = clipPos;

    // ���� texcoord1 �� w ����
    output.texcoord1.w = input.position.w;

    // ������һ֡�Ĳü��ռ�λ��
    float r0_w1 = dot(input.position, mL2W[4]);
    float r0_w2 = dot(input.position, mL2W[3]);
    float r0_w3 = dot(input.position, mL2W[5]);

    float3 prevClipPos = r0_w1 * vmPrevW2P[1].xyz;
    prevClipPos = r0_w2 * vmPrevW2P[0].xyz + prevClipPos;
    prevClipPos = r0_w3 * vmPrevW2P[2].xyz + prevClipPos;
    prevClipPos = input.position.w * vmPrevW2P[3].xyz + prevClipPos;

    // ���� texcoord2
    output.texcoord2.xyz = prevClipPos;
    output.texcoord2.w = input.tangent.w;

    // �����һ��������
    float3 tangentWorld = float3(
        dot(input.tangent.xyz, mL2W[0].xyz),
        dot(input.tangent.xyz, mL2W[1].xyz),
        dot(input.tangent.xyz, mL2W[2].xyz)
    );
    float tangentLength = length(tangentWorld);
    output.texcoord3 = tangentWorld / tangentLength;

    // �����һ���ķ���
    float3 normalWorld = float3(
        dot(mL2WT[0].xyz, input.normal),
        dot(mL2WT[1].xyz, input.normal),
        dot(mL2WT[2].xyz, input.normal)
    );
    float normalLength = length(normalWorld);
    output.texcoord4 = normalWorld / normalLength;

    // ���� texcoord5
    output.texcoord5 = input.texcoord;

    return output;
}