#version 330 core

out vec4 FragColor;

uniform float time;
uniform vec2 resolution;

#define MAX_ITERATIONS 500
#define EPSILON 0.001
#define MAX_DISTANCE 1000

vec3 spherePosition = vec3(cos(time), 0, -2);
const float sphereRadius = 0.5;

float smin( float a, float b, float k )
{
    k *= 6.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - h*h*h*k*(1.0/6.0);
}

float sdPlane( vec3 p, vec3 n, float h )
{
    return dot(p,normalize(n)) + h;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
    vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float map_the_world(vec3 p)
{
    // float distances[] = float[](sdSphere(vec3(-1, 0, -3) - p, 1), 
    //                             sdSphere(vec3(1, 0, -3) - p, 1), 
    //                             sdCappedCylinder(vec3(0, 1.5, -3) - p, 2, 0.75),
    //                             sdSphere(vec3(0, 3.5, -3) - p, 0.75));

    float distances[] = float[](sdSphere(vec3(0, 0, -3) - p, 2),
                                sdCappedCylinder(vec3(0, 0, -3) - p, 0.125, 4));

    float dis = distances[0];
    for(int i = 0; i < 2; i++)
    {
        //dis = smin(distances[i], dis, 0.1);
        dis = min(distances[i], dis);
    }

    return dis;
}

vec3 calculate_normal(vec3 p)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = map_the_world(p + small_step.xyy) - map_the_world(p - small_step.xyy);
    float gradient_y = map_the_world(p + small_step.yxy) - map_the_world(p - small_step.yxy);
    float gradient_z = map_the_world(p + small_step.yyx) - map_the_world(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

vec3 hitColor = vec3(0.2745, 0.3216, 0.3490);

void main()
{
    vec2 uv = (gl_FragCoord.xy / resolution) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    vec3 position = vec3(0, 1, 5);
    vec3 direction = normalize(vec3(uv, -1.0));

    vec3 color = vec3(0, 0, 0);

    for(int i = 0; i < MAX_ITERATIONS; i++)
    {
        float dis = map_the_world(position);

        vec3 gravityCenter = vec3(0, 0, -3);
        float G = 0.0025;

        vec3 toCenter = normalize(gravityCenter - position);
        float blackHoleDistance = length(gravityCenter - position);

        direction = normalize(mix(direction, toCenter, G * blackHoleDistance));

        position += direction * dis;

        if(dis <= EPSILON) // Hit!
        {
            vec3 normal = calculate_normal(position);
            vec3 light_position = vec3(2, -5, -5);
            vec3 direction_to_light = normalize(position - light_position);

            float diffuse_intensity = max(0.0, dot(normal, direction_to_light));

            color = hitColor * diffuse_intensity;
            break;
        }

        if(dis >= MAX_DISTANCE) { break; }
    }

    FragColor = vec4(color, 1.f);
} 
