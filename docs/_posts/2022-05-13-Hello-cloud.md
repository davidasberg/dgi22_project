---
layout: post
title: "Hello Cloud"
date: 2022-05-13 12:31:00 -0000
categories: Blog posts
---
Anders Blomqvist andblomq@kth.se 
David Åsberg dasberg@kth.se 

# From sphere to cloud

From the last blog post, we left off at the ray marched sphere inside a cube mesh. The next step is to render a shape which should resemble a cloud. In the real world, a cloud is a lot of very small liquid droplets, frozen crystals or other particles. When light travels through these particles some light will be absorbed, bounced back into space and some will eventually travel through the cloud. The more particles, the more dense the cloud will be and less light will pass through. This means that the cloud is not a solid object like a rock which makes ray marching a good method for rendering clouds (compared to ray tracing which must find a strict intersection point). 

With ray marching we do not need to find an intersection, instead we will do small steps along a ray and at each step, on the ray, we will ask "how much stuff (cloud) is here?". The answer will give us a density which we will be accumuling to a final color. This is all done in the fragment shader like this:

```c++
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

The `sampleDensity()` function will for now only sample a single 3D noise texture. More on noise textures in a later blog post. The result is shown in the following gif:

![Figure 1. Ray marching a sphere from a noise texture](/dgi22_project/assets/ray-march-noise-sphere.gif)

This does not look like clouds yet but we are still missing a key ingredient: light. At the moment we are only marching through our volume which means there is no light interaction. What we really want is to create an effect where if light has to pass through more cloud - the less light gets transmitted. This can be achieved by doing another ray march at each step where we sample the density, as depicted in the figure below.

![Figure 2. Nr. 1 Only density marching. Nr. 2 density and light marching](/dgi22_project/assets/sketch-raymarching.jpg)

Here we begin a new ray march which starts at the density point and step towards the light. We will accumulate the light by sampling the noise texture again. After the light marching is done we will use Beer's law: $e^{-\tau}$, where $\tau$ is the optical thickness (the accumulated light), to calculate how much light actually got transmitted. This means we need to add a new ray march loop inside the density loop. Beaware that we can not do many light steps because the algorithm is now in $O(n^{2})$ which can cause heavy performance issues.

The general code now looks like this:

```c++
lightMarch(vec3 lightPos)
    float light
    float lightDir = WorldSpaceLightPos
    for step in MAX_LIGHT_STEPS do
        light += sampleDensity(lightPos)
        lightPos += rayDir * LIGHT_STEP_SIZE
    return light

fragment_shader()
    vec3 rayOrigin
    vec3 rayDirection

    float density = 0
    float light = 0
    for step in MAX_STEPS do
        if inside sphere:
            density += sampleDensity()

            accumulatedLight = lightMarch(rayOrigin)
            transmission = exp(-accumulatedLight)
            light += density * transmission;

            rayOrigin += rayDirection * STEP_SIZE

    return light
```

## References
[1] Wikipedia, Beer–Lambert law (https://en.wikipedia.org/wiki/Beer%E2%80%93Lambert_law)
