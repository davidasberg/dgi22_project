---
layout: post
title: "Project Specification"
date: 2022-05-02 15:35:00 -0000
categories: Specification
---
Anders Blomqvist andblomq@kth.se 
David Åsberg dasberg@kth.se 

# DH2323 Project Specification  

We aim for an A grade.
We are going to use the Unity3D engine to render procedurally generated clouds.

Link to our blog: https://davidasberg.github.io/dgi22_project/ 

## Background  

### Ray marching  
Ray Marching is a rendering technique used much like Ray Tracing but typically used when the surfaces are described with functions that are not easily solved. With traditional Ray Tracing, you simply calculate the ray intersection since a simple surface is used, whereas in Ray Marching you march on the ray until you find the intersection. [1]

### Sphere Tracing  
Sphere Tracing is one way of implementing a ray marcher. It is typically used for rendering implicit surfaces usually defined by some continuous function. 

###  Signed Distance Functions (SDF)
Signed distance functions are a way of determining the distance of a given point to a given surface. They are commonly used when implementing the sphere tracing algorithm. 

## Use cases of Ray Marching  
Ray Marching can be used for a lot of different visual effects and other implementations. Our goal is to first implement the core concept of ray marching and then apply it. Examples of applications can be cloud simulations [2] or volumetric lightning (“god rays”) [3]. Other more general applications are [4]:

- Need to render volumetrics that are not uniform
- Rendering implicit functions, fractals
- Rendering other kinds of parametric surfaces where intersection is not known ahead of time, like parallax mapping

## Problem  
We will be implementing a cloud renderer using Ray Marching in Unity. Unity was chosen because of its ease of use and flexibility. Unity gives us an editor where we can easily edit parameters, change the scene and so on. It also gives us the tools to write our own renderer that runs on the GPU using shaders, which are small programs written in a shader language such as GLSL or HLSL. 

## References  
[1] Walczyk, Michael. [Ray Marching](https://michaelwalczyk.com/blog-ray-marching.html)

[2] Brucks, Ryan. [Creating a Volumetric Ray Marcher](https://shaderbits.com/blog/creating-volumetric-ray-marcherhttps://shaderbits.com/blog/creating-volumetric-ray-marcher )

[3] Marty, Valerio. [Raymarched Volumetric Lighting in Unity URP (Part 1)](https://valeriomarty.medium.com/raymarched-volumetric-lighting-in-unity-urp-e7bc84d31604)

[4] Computer Graphics stack exchange.  [What is ray marching?](https://computergraphics.stackexchange.com/questions/161/what-is-ray-marching-is-sphere-tracing-the-same-thing) 
