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

// Following functions are adapted from:
// https://www.cs.utah.edu/~ladislav/dq/dqs.cg
vec3 QuatRotateVector(vec4 q, vec3 v) {
    return v + 2.0*cross(q.xyz, cross(q.xyz, v) + q.w*v);
}

vec3 DualQuatTransformPoint(mat2x4 blendDQ, vec3 p) {
    vec3 t = 2.0*(blendDQ[0].x*blendDQ[1].xyz - blendDQ[1].x*blendDQ[0].xyz + cross(blendDQ[0].xyz, blendDQ[1].yzw));
    return QuatRotateVector(blendDQ[0], p) + t;
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
    blendDQ /= length(blendDQ[0]);
    vec3 position = DualQuatTransformPoint(blendDQ, inPos);
	gl_Position = uboScene.projection * uboScene.view * primitive.model * vec4(position, 1.0);
	
	outNormal = QuatRotateVector(blendDQ[0], inNormal);
	outNormal = normalize(transpose(inverse(mat3(uboScene.view * primitive.model))) * outNormal);

	vec4 pos = uboScene.view * vec4(position, 1.0);
	vec3 lPos = mat3(uboScene.view) * uboScene.lightPos.xyz;
	outLightVec = lPos - pos.xyz;
	outViewVec = -pos.xyz;
}
