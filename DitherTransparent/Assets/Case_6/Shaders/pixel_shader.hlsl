// 定义常量缓冲区
cbuffer $Globals
{
    float4 vEye;
    float4 cSpec;
    float4 vDithAlp;
    float4 vOcRange;
    float4 vOcTarget;      // 被遮挡/遮挡物体位置，应该是镜头发出的射线射到的位置
    float4 mWV[3];
    float vATest;
    int nMtrID;
};

// 定义纹理和采样器
Texture2D sStage0 : register(t0);
Texture2D sRefRough : register(t1);
Texture2D sOcc : register(t2);
Texture2D sNMap : register(t3);

SamplerState __smpsStage0 : register(s0);
SamplerState __smpsRefRough : register(s1);
SamplerState __smpsOcc : register(s2);
SamplerState __smpsNMap : register(s3);

// 定义输入结构体
struct PSInput
{
    float2 pos : SV_Position;
    float2 uv : TEXCOORD0;
    float w : TEXCOORD0_W;
    float3 worldPos  : TEXCOORD1;
    float4 texCoord2 : TEXCOORD2;
    float3 texCoord3 : TEXCOORD3;
    float3 texCoord4 : TEXCOORD4;
    float2 texCoord5 : TEXCOORD5;
};

// 定义输出结构体
struct PSOutput
{
    float4 target0 : SV_Target0;
    float4 target1 : SV_Target1;
    float4 target2 : SV_Target2;
    float4 target3 : SV_Target3;
    float4 target4 : SV_Target4;
    float4 target5 : SV_Target5;
};

// 立即常量缓冲区数据
const float4 icb[16] = {
    float4(0.031250, 0, 0, 0),
    float4(0.531250, 0, 0, 0),
    float4(0.156250, 0, 0, 0),
    float4(0.656250, 0, 0, 0),
    float4(0.781250, 0, 0, 0),
    float4(0.281250, 0, 0, 0),
    float4(0.906250, 0, 0, 0),
    float4(0.406250, 0, 0, 0),
    float4(0.218750, 0, 0, 0),
    float4(0.718750, 0, 0, 0),
    float4(0.093750, 0, 0, 0),
    float4(0.593750, 0, 0, 0),
    float4(0.968750, 0, 0, 0),
    float4(0.468750, 0, 0, 0),
    float4(0.843750, 0, 0, 0),
    float4(0.343750, 0, 0, 0)
};

PSOutput main(PSInput input)
{
    PSOutput output;

    // 采样纹理
    float4 r0 = sStage0.Sample(__smpsStage0, input.texCoord5);

    // 减去透明度测试值
    r0.w = r0.w - vATest;

    // 复制颜色到输出
    output.target0.xyz = r0.xyz;

    // 透明度测试
    bool alphaTestFailed = r0.w < 0.0f;
    if (alphaTestFailed)
    {
        discard;
    }

    // 计算向量差值 worldPos为像素世界空间位置
    float3 diff1 = input.worldPos - vOcTarget.xyz;
    float3 diff2 = vEye.xyz - vOcTarget.xyz;

    // 点积计算
    float dot1 = dot(diff2, diff1);
    float dot2 = dot(diff2, diff2);

    // 除法计算
    float r2_x = dot1 / dot2;

    // 比较操作
    bool isDot1Positive = dot1 >= 0.0f;

    // 向量乘法和加法
    float3 r2_yzw = diff2 * r2_x;
    float3 r0_xyz = r2_x * diff2 - diff1;

    // 点积和平方根计算
    float r1_x = dot(r2_yzw, r2_yzw);
    r1_x = sqrt(r1_x);
    float r1_w = r1_x;
    r1_x = r1_x / r1_w;

    // 进一步计算
    r1_x = 1.0f - r1_x;
    r1_x = 1.0f - r1_x * r1_x;
    r1_x = r1_x * vOcRange.x;
    float r1_y = r1_x * r1_x;
    r1_x = r1_x * vOcRange.y;
    r1_x = r1_x * r1_x;

    // 点积计算
    float r1_z = dot(r0_xyz.xz, r0_xyz.xz);
    float r0_x = dot(r0_xyz, r0_xyz);

    // 除法和比较操作
    float r0_y = r1_z / r1_y;
    r0_y = min(r0_y, 1.0f);
    r0_y = 1.0f - r0_y;
    r0_y = r0_y * r1_x;

    // 平方根计算
    r0.xy = sqrt(r0.xy);

    // 除法和比较操作
    float r0_z = r0.x / r0.y;
    bool r0_x_less_than_y = r0.x < r0.y;

    // 减法和加法操作
    r0_y = r0_z - vOcRange.w;
    float2 r1_xy = float2(1.0f) - vOcRange.zw;

    // 除法和乘法操作
    r0_z = 1.0f / r1_xy.x;
    r0_y = saturate(r0_z * r0_y);

    // 进一步计算
    r0_z = r0_y * -2.0f + 3.0f;
    r0_y = r0_y * r0_y;
    r0_y = r0_y * r0_z;
    r0_y = r1_xy.y * r0_y + vOcRange.z;

    // 条件赋值
    r0.x = r0_x_less_than_y ? r0_y : 1.0f;
    r0.x = isDot1Positive ? r0.x : 1.0f;
    bool vOcRange_z_less_than_1 = vOcRange.z < 1.0f;
    r0.x = vOcRange_z_less_than_1 ? r0.x : 1.0f;

    // 四舍五入和类型转换
    float2 r0_yz = round(input.pos);
    uint2 r0_yz_uint = uint2(r0_yz);

    // 位操作
    uint r0_z_uint = (2 << 0) | (r0_yz_uint.y & 0x3);
    uint r0_y_uint = (2 << 2) | r0_z_uint;

    // 最终计算和测试
    r0.x = vDithAlp.w * r0.x - icb[r0_y_uint].x;
    bool finalTestFailed = r0.x < 0.0f;
    if (finalTestFailed)
    {
        discard;
    }

    // 其他输出初始化为0
    output.target1 = float4(0, 0, 0, 0);
    output.target2 = float4(0, 0, 0, 0);
    output.target3 = float4(0, 0, 0, 0);
    output.target4 = float4(0, 0, 0, 0);
    output.target5 = float4(0, 0, 0, 0);

    return output;
}