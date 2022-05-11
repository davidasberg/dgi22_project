---
layout: post
title: "Our first attempts"
date: 2022-05-11 15:35:00 -0000
categories: Blog posts
---
Anders Blomqvist andblomq@kth.se 
David Åsberg dasberg@kth.se 

# Our first attepmts in graphics programming

At the start of this project, neither of us had any experience in how to program
with shaders which meant our first goal was to get something rendered onto the screen.
This is one of the reasons we choose to work with Unity3D due to it offers a very easy way to get the graphics pipeline up and running compared to doing it from scratch by ourselves. The technique we are implementing is Ray Marching and how this can be used to render volumetric clouds. We began by researching how ray marching could be implemented, both generally and in Unity specifically. The project began quite slow with little to no progress due to we had no idea really where to put things and how everything is connected. It felt as if we just started to learn programming again - which is good because we learn a lot!

However after some time we had a better understanding on how we can create volumetric rendering. We discovered some different methods which we tried and … some worked better than others: 

## The first ray marching steps (method 1)
The first method we tried was to create a default cube with a material assigned to it. The material uses our custom ray marching shader. The shader shoots a ray for each pixel which sees the cube mesh and accumulates color for each step. The color is sampled from a 3D texture at the current ray position. This yielded the result in figure 1. The rainbow colored “stuff” is the volumetric cube and the red cube is just for visual guidance on how an object is submerged into this “stuff”.

![Figure 1. First ray marching test](./../screenshots/first-raymarch-sample.png)

However with this method we had trouble achieving actual volume because this rainbow color was rendered onto the faces of the cube. It was not really 3D and if you flew into the cube nothing was rendered.

## The custom renderer (method 2)

Another method we tried was a “fullscreen render pass” which enables us to hook a custom shader onto the final rendered image before it is shown to the user. By using this method we can define a bounding box in world space which we will fill with stuff. This bounding box will draw on top of everything else (with regards to the z-buffer). By shooting a ray from the camera, for each pixel, we check if this ray intersects with our bounding box. If the ray does, we sample a 3D texture and accumulate the color. The result of this is shown in figure 2. Here we see a black “cloud” and a red box in it. We see less of the red box for rays which passes through more of the cloud.

![Figure 2. First density test](./../screenshots/first-density-test.png)

Here is also a gif which shows the volume aspect of it:

![Figure 3. Density renderer](./../screenshots/density-render.gif)

This seems good but the backside of this method is that it is really hacky. We had to create a custom render feature which was very tricky and it was hard to change parameters on the fly. Most important was that we did not feel like this method was easy to work with.

## The final method

At this point we have only stumbled in the dark and explored different methods. We decided that we want to use a mesh instead of doing a full screen renderpass. At first we tried to combine method 1 and 2 which resulted in some very … odd results, a.k.a improbable art:

![Figure 4. Improbable Art 1](./../screenshots/improbable-art-1.gif)

In the gif above we tried to ray march a box on our 3D cube mesh which failed. We see that the box actually exists but it is being rendered on each face which is not what we want. We want to see a single box as a 3D object within the cube mesh. If that makes sense. The gif also shows a rotating camera which is why it spins.

Here is another improbable art but instead of a cube mesh it is on a sphere:

![Figure 4. Improbable Art 1](./../screenshots/improbable-art-2.gif)

However after getting our vectors and math right we soon ended up with a ray marched 3D sphere inside a cube mesh:

… to be continued.

