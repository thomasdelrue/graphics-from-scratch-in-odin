package main

import "core:math"
import rl "vendor:raylib"


Canvas :: struct {
    w, h: i32
}

Point :: [3]f64

Viewport :: struct {
    w, h, d: f64
}

Sphere :: struct {
    center: Point,
    radius: f64,
    color: rl.Color
}

INF :: 1_000_000_000.
ORIGIN :: Point {0, 0, 0}

PROJECTION_PLANE_D :: 1

canvas_to_viewport :: proc(c: Canvas, v: Viewport, x, y: i32) -> Point {
    return Point {f64(x) * v.w / f64(c.w), f64(y) * v.h / f64(c.h), v.d}
}

canvas_to_pixels_index :: proc(c: Canvas, cx, cy: i32) -> i32 {
    sx := c.w / 2 + cx
    sy := c.h / 2 - cy - 1
    return sy * c.w + sx 
}

trace_ray :: proc(o, d: Point, t_min, t_max: f64, spheres: []Sphere) -> rl.Color {
    closest_t := INF
    closest_sphere : ^Sphere = nil

    for &sphere in spheres {
        t1, t2 := intersect_ray_sphere(o, d, sphere)
        if t1 >= t_min && t1 <= t_max && t1 < closest_t {
            closest_t = t1
            closest_sphere = &sphere
        }
        if t2 >= t_min && t2 <= t_max && t2 < closest_t {
            closest_t = t2
            closest_sphere = &sphere
        }
    }
    if closest_sphere == nil {
        return rl.WHITE
    }

    return closest_sphere.color
}

intersect_ray_sphere :: proc(o, d: Point, sphere: Sphere) -> (f64, f64) {
    r := sphere.radius
    co := o - sphere.center

    a := dot(d, d)
    b := 2 * dot(co, d)
    c := dot(co, co) - r * r

    discriminant : f64 = b * b - 4 * a * c
    if discriminant < 0 {
        return INF, INF
    }

    t1 := (-b + math.sqrt(discriminant)) / (2 * a)
    t2 := (-b - math.sqrt(discriminant)) / (2 * a)

    return t1, t2
}

dot :: proc(v, w: Point) -> f64 {
    return v[0] * w[0] + v[1] * w[1] + v[2] * w[2]
}

main :: proc() {
    canvas := Canvas {600, 600}
    viewport := Viewport {1, 1, PROJECTION_PLANE_D}

    pixels := make([]rl.Color, canvas.w * canvas.h)
    defer delete(pixels)

    spheres := []Sphere {
        Sphere {center=Point{0, -1, 3}, radius=1, color=rl.Color{255, 0, 0, 255}},
        Sphere {center=Point{2, 0, 4}, radius=1, color=rl.Color{0, 0, 255, 255}},
        Sphere {center=Point{-2, 0, 4}, radius=1, color=rl.Color{0, 255, 0, 255}}
    }

    rl.InitWindow(canvas.w, canvas.h, "Raytracer example")
    defer rl.CloseWindow()

    initial_image := rl.GenImageColor(canvas.w, canvas.h, rl.BLANK)
    texture := rl.LoadTextureFromImage(initial_image)
    rl.UnloadImage(initial_image)
    defer rl.UnloadTexture(texture)



    for !rl.WindowShouldClose() {
        for x in -canvas.w / 2 ..< canvas.w / 2 {
            for y in -canvas.h / 2..< canvas.h / 2 {
                d := canvas_to_viewport(canvas, viewport, x, y)
                color := trace_ray(ORIGIN, d, 1, INF, spheres)
                pixels[canvas_to_pixels_index(canvas, x, y)] = color
            }
        } 

        rl.UpdateTexture(texture, raw_data(pixels))

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.DrawTexture(texture, 0, 0, rl.WHITE)

        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }
}
