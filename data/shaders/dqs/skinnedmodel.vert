#version 450

layout (location = 0) in vec3 inPos;
layout (location = 1) in vec3 inNormal;
layout (location = 2) in vec2 inUV;
layout (location = 3) in vec3 inColor;
layout (location = 4) in vec4 inJointIndices;
layout (location = 5) in vec4 inJointWeights;

layout (set = 0, binding = 0) uniform UBOScene
{
	mat4 projection;
	mat4 view;
	vec4 lightPos;
} uboScene;

layout(push_constant) uniform PushConsts {
	mat4 model;
} primitive;

layout(std430, set = 1, binding = 0) readonly buffer JointMatrices {
	mat2x4 jointDQuats[];
};

layout (location = 0) out vec3 outNormal;
layout (location = 1) out vec3 outColor;
layout (location = 2) out vec2 outUV;
layout (location = 3) out vec3 outViewVec;
layout (location = 4) out vec3 outLightVec;

// https://gamedev.stackexchange.com/questions/164423/help-with-dual-quaternion-skinning
mat4 GetSkinMatrix(mat2x4 bone)
{
    vec4 r = bone[0];
    vec4 t = bone[1];

    return mat4(
        1.0 - (2.0 * r.y * r.y) - (2.0 * r.z * r.z),
              (2.0 * r.x * r.y) + (2.0 * r.w * r.z),
              (2.0 * r.x * r.z) - (2.0 * r.w * r.y),
        0.0,

              (2.0 * r.x * r.y) - (2.0 * r.w * r.z),
        1.0 - (2.0 * r.x * r.x) - (2.0 * r.z * r.z),
              (2.0 * r.y * r.z) + (2.0 * r.w * r.x),
        0.0,

              (2.0 * r.x * r.z) + (2.0 * r.w * r.y),
              (2.0 * r.y * r.z) - (2.0 * r.w * r.x),
        1.0 - (2.0 * r.x * r.x) - (2.0 * r.y * r.y),
        0.0,

        2.0 * (-t.w * r.x + t.x * r.w - t.y * r.z + t.z * r.y),
        2.0 * (-t.w * r.y + t.x * r.z + t.y * r.w - t.z * r.x),
        2.0 * (-t.w * r.z - t.x * r.y + t.y * r.x + t.z * r.w),
        1);
}

// https://gist.github.com/gszauer/3ff5001f4df5b86d2a74c74239eadea3
vec3 QuatRotateVector(vec4 q, vec3 v) {
    vec3 u = vec3(q.x, q.y, q.z);
    float s = q.w;

    return 2.0 * dot(u, v) * u + (s * s - dot(u, u)) * v + 2.0 * s * cross(u, v);
}

vec4 QMul(vec4 p, vec4 q) {
	vec3 q_v = vec3(q.x, q.y, q.z);
    vec3 p_v = vec3(p.x, p.y, p.z);

    float q_r = q.w;
    float p_r = p.w;

    float scalar = q_r * p_r - dot(q_v, p_v);
    vec3 vector = (p_v * q_r) + (q_v * p_r) + cross(p_v, q_v);

    return vec4(vector.x, vector.y, vector.z, scalar);
}

vec3 DualQuatTransformPoint(vec4 Qr, vec4 Qd, vec3 p) {
	// Important to remember that we're doing quaternion multiplication
	vec4 t = QMul(2.0 * Qd, vec4(-Qr.x, -Qr.y, -Qr.z, Qr.w));

    return QuatRotateVector(Qr, p) + t.xyz;
}

void main() 
{
	outNormal = inNormal;
	outColor = inColor;
	outUV = inUV;

	mat2x4 blendDQ = 
		inJointWeights.x * jointDQuats[int(inJointIndices.x)] +
		inJointWeights.y * jointDQuats[int(inJointIndices.y)] +
		inJointWeights.z * jointDQuats[int(inJointIndices.z)] +
		inJointWeights.w * jointDQuats[int(inJointIndices.w)];

    vec3 position = DualQuatTransformPoint(blendDQ[0], blendDQ[1], inPos.xyz);
	gl_Position = uboScene.projection * uboScene.view * primitive.model * vec4(position, 1.0);
	
    mat4 skinMat = mat4(1.0);
	outNormal = normalize(transpose(inverse(mat3(uboScene.view * primitive.model * skinMat))) * inNormal);

	vec4 pos = uboScene.view * vec4(position, 1.0);
	vec3 lPos = mat3(uboScene.view) * uboScene.lightPos.xyz;
	outLightVec = lPos - pos.xyz;
	outViewVec = -pos.xyz;
}
