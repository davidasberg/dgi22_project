---
layout: post
title: "Hello cloud"
date: 2022-05-13 15:35:00 -0000
categories: Blog posts
---
Anders Blomqvist andblomq@kth.se 
David Åsberg dasberg@kth.se 

# From sphere to cloud

From the last blog post, we left off at the ray marched sphere inside a cube mesh. The next step is to render a shape which should resemble a cloud. In the real world, a cloud is a lot of very small liquid droplets, frozen crystals or other particles. When light travels through these particles some light will be absorbed, bounced back into space and some will eventually travel through the cloud. The more particles, the more dense the cloud will be and less light will pass through. This means that the cloud is not a solid object like a rock which makes ray marching a good method for rendering clouds (compared to ray tracing which must find a strict intersection point). 

With ray marching we do not need to find an intersection, instead we will do small steps along a ray and at each step, on the ray, we will ask "how much stuff (cloud) is here?". The answer will give us a density which we will be accumuling to a final color. This is all done in the fragment shader like this:

```
fragment_shader()
    vec3 rayOrigin
    vec3 rayDirection

    float density = 0
    for step in MAX_STEPS do
        if inside sphere:
            density += sampleDensity()
            rayOrigin += rayDirection * STEP_SIZE
    return density
```

The `sampleDensity()` function will for now only sample a single 3D noise texture. More on noise textures later. The result is shown in the following gif:

![Figure 1. Ray marching a sphere from a noise texture](/dgi22_project/assets/ray-march-noise-sphere.gif)

... too be continued
