#include <klein/klein.hpp>
#include <glm/glm.hpp>
#include <stdio.h>

using namespace glm;

kln::motor kln_exp(kln::line l)
{
    const vec4 &a = reinterpret_cast<const vec4 &>(l.p1_);
    const vec4 &b = reinterpret_cast<const vec4 &>(l.p2_);
    vec4 a2 = vec4(dot(a, a));
    vec4 ab = vec4(dot(a, b));

    // if (a2.x < 0.01)
    //     return kln::motor(_mm_set_ps(1.0, b.x, b.y, b.z), _mm_set1_ps(0.0));

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

    return kln::motor(_mm_set_ps(p1_out.x, p1_out.y, p1_out.z, p1_out.w), _mm_set_ps(p2_out.x, p2_out.y, p2_out.z, p2_out.w));
}

void print_motor(const kln::motor &m)
{
    float p1[4];
    float p2[4];
    _mm_store_ps(p1, m.p1_);
    _mm_store_ps(p2, m.p2_);
    printf("Motor:  %f %f %f %f\n        %f %f %f %f\n", p1[0], p1[1], p1[2], p1[3], p2[0], p2[1], p2[2], p2[3]);
}

int main(int argc, char **argv)
{
    kln::rotor r{M_PI * 0.5, 0.0, 0.0, 1.0};
    kln::translator t{1.0, 0.0, 1.0, 1.0};
    kln::motor m = r * t;
    kln::line l = log(m);

    while (true)
    {
        kln::motor m1 = exp(l);
        kln::motor m2 = kln_exp(l);
        print_motor(m1);
        print_motor(m2);
    }
    return 0;
}
