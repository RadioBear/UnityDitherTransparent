// 定义全局常量缓冲区
cbuffer $Globals
{
    row_major float4x4 mW2P;           // Offset:    0 Size:    64
    float4 mL2WT[3];                   // Offset:   64 Size:    48
    float4 mL2W[6];                    // Offset:  112 Size:    96
    row_major float4x4 vmPrevW2P;      // Offset:  208 Size:    64
};

// 定义顶点输入结构体
struct VS_INPUT
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float4 tangent : TANGENT;
};

// 定义顶点输出结构体
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

// 顶点着色器函数
VS_OUTPUT main(VS_INPUT input)
{
    VS_OUTPUT output;

    // 计算中间结果 r0
    float r0_y = dot(input.position, mL2W[1]);
    float r0_x = dot(input.position, mL2W[0]);
    float r0_z = dot(input.position, mL2W[2]);

    // 计算 r1
    float4 r1 = r0_y * mW2P[1];
    r1 = r0_x * mW2P[0] + r1;
    r1 = r0_z * mW2P[2] + r1;

    // 设置 o2 的 xyz 分量
    output.texcoord1.xyz = float3(r0_x, r0_y, r0_z);

    // 计算最终的裁剪空间位置
    float4 clipPos = input.position.w * mW2P[3] + r1;

    // 设置输出的位置和 texcoord0
    output.position = clipPos;
    output.texcoord0 = clipPos;

    // 设置 texcoord1 的 w 分量
    output.texcoord1.w = input.position.w;

    // 计算上一帧的裁剪空间位置
    float r0_w1 = dot(input.position, mL2W[4]);
    float r0_w2 = dot(input.position, mL2W[3]);
    float r0_w3 = dot(input.position, mL2W[5]);

    float3 prevClipPos = r0_w1 * vmPrevW2P[1].xyz;
    prevClipPos = r0_w2 * vmPrevW2P[0].xyz + prevClipPos;
    prevClipPos = r0_w3 * vmPrevW2P[2].xyz + prevClipPos;
    prevClipPos = input.position.w * vmPrevW2P[3].xyz + prevClipPos;

    // 设置 texcoord2
    output.texcoord2.xyz = prevClipPos;
    output.texcoord2.w = input.tangent.w;

    // 计算归一化的切线
    float3 tangentWorld = float3(
        dot(input.tangent.xyz, mL2W[0].xyz),
        dot(input.tangent.xyz, mL2W[1].xyz),
        dot(input.tangent.xyz, mL2W[2].xyz)
    );
    float tangentLength = length(tangentWorld);
    output.texcoord3 = tangentWorld / tangentLength;

    // 计算归一化的法线
    float3 normalWorld = float3(
        dot(mL2WT[0].xyz, input.normal),
        dot(mL2WT[1].xyz, input.normal),
        dot(mL2WT[2].xyz, input.normal)
    );
    float normalLength = length(normalWorld);
    output.texcoord4 = normalWorld / normalLength;

    // 设置 texcoord5
    output.texcoord5 = input.texcoord;

    return output;
}