#include <vector>
#include <klein/klein.hpp>

double calculate_volume(
    const std::vector<VulkanglTFModel::Vertex> &vertexBuffer,
    const std::vector<uint32_t> &indexBuffer)
{
    std::vector<kln::point> pga_points;
    for (VulkanglTFModel::Vertex v : vertexBuffer)
        pga_points.push_back(kln::point(v.pos.x, v.pos.y, v.pos.z));

    kln::plane sum_triangles = kln::plane();
    for (uint32_t i = 0; i < indexBuffer.size(); i += 3)
    {
        kln::point v1 = pga_points[indexBuffer[i]];
        kln::point v2 = pga_points[indexBuffer[i + 1]];
        kln::point v3 = pga_points[indexBuffer[i + 2]];
        kln::plane triangle = v1 & v2 & v3;
        sum_triangles += triangle;
    }

    return (!sum_triangles).w() / 6.0;
}

std::vector<double> calculate_local_detail(
    const std::vector<VulkanglTFModel::Vertex> &vertexBuffer,
    const std::vector<uint32_t> &indexBuffer)
{
    std::vector<kln::point> pga_points;
    for (VulkanglTFModel::Vertex v : vertexBuffer)
        pga_points.push_back(kln::point(v.pos.x, v.pos.y, v.pos.z));

    std::vector<double> vtx_curvature(vertexBuffer.size());
    for (uint32_t it_count = 0; it_count < indexBuffer.size(); it_count += 3)
    {
        kln::point v1 = pga_points[indexBuffer[it_count]];
        kln::point v2 = pga_points[indexBuffer[it_count + 1]];
        kln::point v3 = pga_points[indexBuffer[it_count + 2]];

        kln::plane face = v1 & v2 & v3;
        std::vector<kln::line> edges = {v3 & v1, v1 & v2, v2 & v3};
        for (uint8_t i = 0; i < 3; ++i)
            vtx_curvature[indexBuffer[it_count + i]] += (edges[i] | edges[(i + 1) % 3]) / face.norm();
    }

    return vtx_curvature;
}

double diff_percent(double a, double b)
{
    if (abs(a) > 0.01 && abs(b) > 0.01)
        return abs(a - b) / (0.5 * (a + b));
    return 0.0;
}
