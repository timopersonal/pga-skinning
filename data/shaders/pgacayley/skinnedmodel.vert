#version 450

// #include https://github.com/jeremyong/klein/blob/master/glsl/klein.glsl
#ifndef KLEIN_GUARD
#define KLEIN_GUARD

// p0 -> (e0, e1, e2, e3)
// p1 -> (1, e23, e31, e12)
// p2 -> (e0123, e01, e02, e03)
// p3 -> (e123, e032, e013, e021)

struct kln_plane
{
    vec4 p0;
};

struct kln_line
{
    vec4 p1;
    vec4 p2;
};

// If integrating this library with other code, remember that the point layout
// here has the homogeneous component in p3[0] and not p3[3]. The swizzle to
// get the vec3 Cartesian representation is p3.yzw
struct kln_point
{
    vec4 p3;
};

struct kln_rotor
{
    vec4 p1;
};

struct kln_translator
{
    vec4 p2;
};

struct kln_motor
{
    vec4 p1;
    vec4 p2;
};

kln_rotor kln_mul(in kln_rotor a, in kln_rotor b)
{
    kln_rotor c;
    c.p1 = a.p1.x * b.p1;
    c.p1 -= a.p1.yzwy * b.p1.ywyz;

    vec4 t = a.p1.zyzw * b.p1.zxxx;
    t += a.p1.wwyz * b.p1.wzwy;
    t.x = -t.x;

    c.p1 += t;
    return c;
}

kln_translator kln_mul(in kln_translator a, in kln_translator b)
{
    // (1 + a.p2) * (1 + b.p2) = 1 + a.p2 + b.p2
    kln_translator c;
    c.p2 = a.p2 + b.p2;
    return c;
}

kln_motor kln_mul(in kln_motor a, in kln_motor b)
{
    kln_motor c;
    vec4 a_zyzw = a.p1.zyzw;
    vec4 a_ywyz = a.p1.ywyz;
    vec4 a_wzwy = a.p1.wzwy;
    vec4 c_wwyz = b.p1.wwyz;
    vec4 c_yzwy = b.p1.yzwy;

    c.p1 = a.p1.x * b.p1;
    vec4 t = a_ywyz * c_yzwy;
    t += a_zyzw * b.p1.zxxx;
    t.x = -t.x;
    c.p1 += t;
    c.p1 -= a_wzwy * c_wwyz;

    c.p2 = a.p1.x * b.p2;
    c.p2 += a.p2 * b.p1.x;
    c.p2 += a_ywyz * b.p2.yzwy;
    c.p2 += a.p2.ywyz * c_yzwy;
    t = a_zyzw * b.p2.zxxx;
    t += a_wzwy * b.p2.wwyz;
    t += a.p2.zxxx * b.p1.zyzw;
    t += a.p2.wzwy * c_wwyz;
    t.x = -t.x;
    c.p2 -= t;
    return c;
}

kln_plane kln_apply(in kln_rotor r, in kln_plane p)
{
    vec4 dc_scale = vec4(1.0, 2.0, 2.0, 2.0);
    vec4 neg_low = vec4(-1.0, 1.0, 1.0, 1.0);

    vec4 t1 = r.p1.zxxx * r.p1.zwyz;
    t1 += r.p1.yzwy * r.p1.yyzw;
    t1 *= dc_scale;

    vec4 t2 = r.p1 * r.p1.xwyz;
    t2 -= (r.p1.wxxx * r.p1.wzwy) * neg_low;
    t2 *= dc_scale;

    vec4 t3 = r.p1 * r.p1;
    t3 -= r.p1.xwyz * r.p1.xwyz;
    t3 += r.p1.xxxx * r.p1.xxxx;
    t3 -= r.p1.xzwy * r.p1.xzwy;

    // TODO: provide variadic rotor-plane application
    kln_plane q;
    q.p0 = t1 * p.p0.xzwy;
    q.p0 += t2 * p.p0.xwyz;
    q.p0 += t3 * p.p0;
    return q;
}

kln_plane kln_apply(in kln_motor m, in kln_plane p)
{
    vec4 dc_scale = vec4(1.0, 2.0, 2.0, 2.0);
    vec4 neg_low = vec4(-1.0, 1.0, 1.0, 1.0);

    vec4 t1 = m.p1.zxxx * m.p1.zwyz;
    t1 += m.p1.yzwy * m.p1.yyzw;
    t1 *= dc_scale;

    vec4 t2 = m.p1 * m.p1.xwyz;
    t2 -= (m.p1.wxxx * m.p1.wzwy) * neg_low;
    t2 *= dc_scale;

    vec4 t3 = m.p1 * m.p1;
    t3 -= m.p1.xwyz * m.p1.xwyz;
    t3 += m.p1.xxxx * m.p1.xxxx;
    t3 -= m.p1.xzwy * m.p1.xzwy;

    vec4 t4 = m.p1.x * m.p2;
    t4 += m.p1.xzwy * m.p2.xwyz;
    t4 += m.p1 * m.p2.x;
    t4 -= m.p1.xwyz * m.p2.xzwy;
    t4 *= vec4(0.0, 2.0, 2.0, 2.0);

    // TODO: provide variadic motor-plane application
    kln_plane q;
    q.p0 = t1 * p.p0.xzwy;
    q.p0 += t2 * p.p0.xwyz;
    q.p0 += t3 * p.p0;
    q.p0 += vec4(dot(t4, p.p0), 0.0, 0.0, 0.0);
    return q;
}

kln_point kln_apply(in kln_rotor r, in kln_point p)
{
    vec4 scale = vec4(0, 2, 2, 2);

    vec4 t1 = r.p1 * r.p1.xwyz;
    t1 -= r.p1.x * r.p1.xzwy;
    t1 *= scale;

    vec4 t2 = r.p1.x * r.p1.xwyz;
    t2 += r.p1.xzwy * r.p1;
    t2 *= scale;

    vec4 t3 = r.p1 * r.p1;
    t3 += r.p1.yxxx * r.p1.yxxx;
    vec4 t4 = r.p1.zwyz * r.p1.zwyz;
    t4 += r.p1.wzwy * r.p1.wzwy;
    t3 -= t4 * vec4(-1.0, 1.0, 1.0, 1.0);

    // TODO: provide variadic rotor-point application
    kln_point q;
    q.p3 = t1 * p.p3.xwyz;
    q.p3 += t2 * p.p3.xzwy;
    q.p3 += t3 * p.p3;
    return  q;
}

kln_point kln_apply(in kln_motor m, in kln_point p)
{
    vec4 scale = vec4(0, 2, 2, 2);

    vec4 t1 = m.p1 * m.p1.xwyz;
    t1 -= m.p1.x * m.p1.xzwy;
    t1 *= scale;

    vec4 t2 = m.p1.x * m.p1.xwyz;
    t2 += m.p1.xzwy * m.p1;
    t2 *= scale;

    vec4 t3 = m.p1 * m.p1;
    t3 += m.p1.yxxx * m.p1.yxxx;
    vec4 t4 = m.p1.zwyz * m.p1.zwyz;
    t4 += m.p1.wzwy * m.p1.wzwy;
    t3 -= t4 * vec4(-1.0, 1.0, 1.0, 1.0);

    t4 = m.p1.xzwy * m.p2.xwyz;
    t4 -= m.p1.x * m.p2;
    t4 -= m.p1.xwyz * m.p2.xzwy;
    t4 -= m.p1 * m.p2.x;
    t4 *= scale;

    // TODO: provide variadic motor-point application
    kln_point q;
    q.p3 = t1 * p.p3.xwyz;
    q.p3 += t2 * p.p3.xzwy;
    q.p3 += t3 * p.p3;
    q.p3 += t4 * p.p3.x;
    return  q;
}

// If no entity is provided as the second argument, the motor is
// applied to the origin.
// NOTE: The motor MUST be normalized for the result of this operation to be
// well defined.
kln_point kln_apply(in kln_motor m)
{
    kln_point p;
    p.p3 = m.p1 * m.p2.x;
    p.p3 += m.p1.x * m.p2;
    p.p3 += m.p1.xwyz * m.p2.xzwy;
    p.p3 = m.p1.xzwy * m.p2.xwyz - p.p3;
    p.p3 *= vec4(0.0, 2.0, 2.0, 2.0);
    p.p3.x = 1.0;
    return p;
}

#endif // KLEIN_GUARD

kln_motor kln_exp(in kln_line l)
{
    vec4 a = l.p1;
    vec4 b = l.p2;
    vec4 a2 = vec4(dot(a, a));
    vec4 ab = vec4(dot(a, b));

    // if (a2.x < 0.01)
    //     return kln_motor(vec4(1, b), vec4(0.0));

    vec4 a2_sqrt_rcp = vec4(1.0) / sqrt(a2);
    vec4 u = a2 * a2_sqrt_rcp;
    vec4 minus_v = ab * a2_sqrt_rcp;
    vec4 norm_real = a * a2_sqrt_rcp;
    vec4 norm_ideal = b * a2_sqrt_rcp;
    norm_ideal = norm_ideal - (a * (ab * (a2_sqrt_rcp / a2)));
    vec2 uv = vec2(u.x, minus_v.x);
    vec2 sincosu = vec2(sin(uv.x), cos(uv.x));
    vec4 sinu = vec4(sincosu.x);
    vec4 p1_out = vec4(sincosu.y, vec3(0.0)) + (sinu * norm_real);

    vec4 cosu = vec4(0.0, vec3(sincosu.y));
    vec4 minus_vcosu = minus_v * cosu;
    vec4 p2_out = sinu * norm_ideal;
    p2_out = p2_out + (minus_vcosu * norm_real);
    float minus_vsinu = uv.y * sincosu.x;
    p2_out = vec4(minus_vsinu, vec3(0.0)) + p2_out;

    return kln_motor(p1_out, p2_out);
}

kln_line kln_scale(kln_line l, float f)
{
    return kln_line(l.p1 * f, l.p2 * f);
}

kln_motor kln_scale(kln_motor m, float f)
{
    return kln_motor(m.p1 * f, m.p2 * f);
}

kln_motor kln_add(kln_motor l1, kln_motor l2)
{
    return kln_motor(l1.p1 + l2.p1, l1.p2 + l2.p2);
}

kln_line kln_add(kln_line l1, kln_line l2)
{
    return kln_line(l1.p1 + l2.p1, l1.p2 + l2.p2);
}

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
	kln_motor jointMotors[];
};

layout (location = 0) out vec3 outNormal;
layout (location = 1) out vec3 outColor;
layout (location = 2) out vec2 outUV;
layout (location = 3) out vec3 outViewVec;
layout (location = 4) out vec3 outLightVec;

struct cayley_trans {
    vec3 real;
    vec3 dual;
};

// https://marc-b-reynolds.github.io/quaternions/2016/05/30/QuatHDAngleCayley.html
vec3 q_cayley(vec4 q) {
    return q.xyz*(1.0/(1.0+q.w));
}

vec4 q_cayley(vec3 v) {
    float s = 2.0/(1.0+dot(v,v)); // 2/(1+b^2)
    return vec4(s*v, s-1.0);
}

cayley_trans cayley_from_motor(kln_motor m)
{
    return cayley_trans(q_cayley(m.p1), q_cayley(m.p2));
}

kln_motor motor_from_cayley(cayley_trans t)
{
    return kln_motor(q_cayley(t.real), q_cayley(t.dual));
}

cayley_trans cayley_add(cayley_trans t1, cayley_trans t2)
{
    return cayley_trans(t1.real + t2.real, t1.dual + t2.dual);
}

cayley_trans cayley_scale(cayley_trans t, float factor)
{
    return cayley_trans(t.real * factor, t.dual * factor);
}

void main() 
{
	outNormal = inNormal;
	outColor = inColor;
	outUV = inUV;

    kln_point untr_p = { vec4(1.0, inPos.xyz) };
    kln_motor blend_motor = motor_from_cayley(
        cayley_add(cayley_scale(cayley_from_motor(jointMotors[int(inJointIndices.x)]), inJointWeights.x),
                cayley_add(cayley_scale(cayley_from_motor(jointMotors[int(inJointIndices.y)]), inJointWeights.y),
                        cayley_add(cayley_scale(cayley_from_motor(jointMotors[int(inJointIndices.z)]), inJointWeights.z),
                                cayley_scale(cayley_from_motor(jointMotors[int(inJointIndices.w)]), inJointWeights.w))))
    );

    kln_point tr_p = kln_apply(blend_motor, untr_p);
	gl_Position = uboScene.projection * uboScene.view * primitive.model * vec4(tr_p.p3.yzw, 1.0);
	
    mat4 skinMat = mat4(1.0);
	outNormal = normalize(transpose(inverse(mat3(uboScene.view * primitive.model * skinMat))) * inNormal);
    kln_point untr_n = { vec4(0.0, outNormal.xyz) };
    outNormal = kln_apply(blend_motor, untr_n).p3.wzy;

	vec4 pos = uboScene.view * vec4(inPos, 1.0);
	vec3 lPos = mat3(uboScene.view) * uboScene.lightPos.xyz;
	outLightVec = lPos - pos.xyz;
	outViewVec = -pos.xyz;
}
