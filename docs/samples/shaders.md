### Hello World - main.rb
```ruby
  # ./samples/14_shaders/01_hello_world/app/main.rb
  require "shaders/effect.frag.hlsl"

  module Main
    def start
    end

    def tick
      outputs.shader = {
        path: "shaders/effect.frag.hlsl"
      }

      outputs.primitives << {
        x: 640,
        y: 360,
        w: 100,
        h: 100,
        path: "sprites/square/blue.png",
        anchor_x: 0.5,
        anchor_y: 0.5
      }
    end
  end

  DR.reset

```

### Flow Like Water - main.rb
```ruby
  # ./samples/14_shaders/02_flow_like_water/app/main.rb
  require "shaders/effect.frag.hlsl"

  module Main
    def start
    end

    def tick
      sprite_size = 720

      outputs[:water].set w: 1280, h: 720, background_color: [255, 255, 255]
      outputs[:water].primitives << 3.map do |i|
        [
          { x: 0,
            y: Grid.h / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water.png", a: 128 },
          { x: 720,
            y: Grid.h / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water.png", a: 128 },
          { x: Grid.w / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            y: 0,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water.png", a: 128 },
        ]
      end

      outputs[:displacement].set w: 1280, h: 720, background_color: [255, 255, 255]
      outputs[:displacement].primitives << 3.map do |i|
        [
          { x: Grid.w / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            y: 0,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water-displacement.png", a: 128 },
          { x: 0,
            y: Grid.h / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water-displacement.png", a: 128 },
          { x: 720,
            y: Grid.h / 2 - i * sprite_size + Kernel.tick_count % sprite_size,
            w: sprite_size, h: sprite_size,
            path: "sprites/flow-like-water/water-displacement.png", a: 128 }
        ]
      end

      outputs.shader = {
        path: "shaders/effect.frag.hlsl",
        textures: [:displacement]
      }

      outputs.primitives << { x: 0, y: 0, w: 1280, h: 720, path: :water }

      outputs.primitives << { x: Kernel.tick_count % 1280,
                              y: Kernel.tick_count % 720,
                              text: "flow like water",
                              scale_quality_enum: 0,
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              size_px: 100,
                              r: 1, g: 1, b: 1 }

      outputs.primitives << { x: inputs.mouse.x,
                              y: inputs.mouse.y,
                              w: 64, h: 64,
                              path: "sprites/square/blue.png",
                              anchor_x: 0.5, anchor_y: 0.5 }
    end
  end

  DR.reset

```

### Shaders On Render Targets - main.rb
```ruby
  # ./samples/14_shaders/03_shaders_on_render_targets/app/main.rb
  require "shaders/blue_left_side.fragment.hlsl"
  require "shaders/blue_right_side.fragment.hlsl"

  module Main
    def start
    end

    def tick
      outputs[:le_circle].set w: 100, h: 100, background_color: [0, 0, 0, 0]
      outputs[:le_circle].shader = {
        path: "shaders/blue_left_side.fragment.hlsl"
      }

      outputs[:le_circle].primitives << {
        x: 0,
        y: 0,
        w: 100,
        h: 100,
        path: "sprites/circle/blue.png",
        anchor_x: 0,
        anchor_y: 0
      }

      outputs[:le_square].set w: 100, h: 100, background_color: [0, 0, 0, 0]
      outputs[:le_square].shader = {
        path: "shaders/blue_right_side.fragment.hlsl"
      }

      outputs[:le_square].primitives << {
        x: 0,
        y: 0,
        w: 100,
        h: 100,
        path: "sprites/square/blue.png",
        anchor_x: 0,
        anchor_y: 0
      }

      outputs.primitives << {
        x: 640 + 100,
        y: 360,
        w: 100,
        h: 100,
        path: :le_square,
        anchor_x: 0.5,
        anchor_y: 0.5
      }

      outputs.primitives << {
        x: 640 - 100,
        y: 360,
        w: 100,
        h: 100,
        path: :le_circle,
        anchor_x: 0.5,
        anchor_y: 0.5
      }
    end
  end

  DR.reset

```

### Uniforms - main.rb
```ruby
  # ./samples/14_shaders/04_uniforms/app/main.rb
  require "shaders/time_and_mouse.fragment.hlsl"

  module Main
    def start
    end

    def tick
      outputs.background_color = [0, 0, 0]
      outputs.shader = {
        path: "shaders/time_and_mouse.fragment.hlsl",
        uniforms: [
          { type: :int, value: Kernel.tick_count },
          { type: :float, value: inputs.mouse.x.fdiv(Grid.w) },
          { type: :float, value: inputs.mouse.y.fdiv(Grid.h) },
        ]
      }
    end
  end

  DR.reset

```

### Ripple Effects - main.rb
```ruby
  # ./samples/14_shaders/05_ripple_effects/app/main.rb
  # https://www.youtube.com/watch?v=8rCRsOLiO7k

  require "shaders/ripples.frag.hlsl"

  module Main
    def start
      @ripple_queue = []
    end

    def tick
      if inputs.mouse.click
        @ripple_queue << { x: inputs.mouse.x, y: inputs.mouse.y, at: Kernel.tick_count, duration: 120 }
      end

      @ripple_queue.reject! do |ripple|
        ripple.at.elapsed_time(Kernel.tick_count) > ripple.duration
      end

      outputs[:displacement].set w: 1280, h: 720, background_color: [0, 0, 0, 0]
      outputs[:displacement].primitives << scrolling_tiles(
        tile_size: 275,
        viewport_w: 1280,
        viewport_h: 720,
        dx: 0.1,
        dy: 0.0,
        path: "sprites/displacement.png",
        tick_count: Kernel.tick_count
      )

      outputs[:displacement].primitives << @ripple_queue.map do |ripple|
        perc = Easing.smooth_stop(start_at: ripple.at,
                                 duration: ripple.duration,
                                 power: 2,
                                 tick_count: Kernel.tick_count)
        {
          x: ripple.x,
          y: ripple.y,
          w: 128 * perc,
          h: 128 * perc,
          path: "sprites/ripple.png",
          anchor_x: 0.5,
          anchor_y: 0.5,
          a: 128 * (1 - perc)
        }
      end

      outputs[:soup].set w: 1280, h: 720, background_color: [0, 0, 0, 0]
      outputs[:soup].primitives << scrolling_tiles(
        tile_size: 546,
        viewport_w: 1280,
        viewport_h: 720,
        dx: 0.2,
        dy: 0.2,
        tick_count: Kernel.tick_count,
        path: "sprites/soup-left.png",
        a: 128
      )

      outputs[:soup].primitives << scrolling_tiles(
        tile_size: 546,
        viewport_w: 1280,
        viewport_h: 720,
        dx: -0.1,
        dy: 0.1,
        tick_count: Kernel.tick_count,
        path: "sprites/soup-right.png",
        a: 128
      )

      outputs[:soup].primitives << @ripple_queue.map do |ripple|
        perc = Easing.smooth_stop(start_at: ripple.at,
                                 duration: ripple.duration,
                                 power: 2,
                                 tick_count: Kernel.tick_count)
        {
          x: ripple.x,
          y: ripple.y,
          w: 256 * perc,
          h: 256 * perc,
          path: "sprites/ripple.png",
          anchor_x: 0.5,
          anchor_y: 0.5,
          a: 128 * (1 - perc)
        }
      end

      outputs[:mask].set w: 1280, h: 720, background_color: [0, 0, 0, 0]
      outputs[:mask].primitives << { x: 635,
                                     y: 365,
                                     w: 475,
                                     h: 475,
                                     path: "sprites/circle/solid.png",
                                     r: 0, g: 0, b: 0,
                                     anchor_x: 0.5, anchor_y: 0.5 }

      outputs[:scene].shader = {
        path: "shaders/ripples.frag.hlsl",
        textures: [
          :displacement,
          :soup,
          :mask
        ],
      }

      outputs[:scene].set w: 1280, h: 720, background_color: [219, 208, 191]
      outputs[:scene].primitives << { x: 640,
                                      y: 360,
                                      w: 933,
                                      h: 700,
                                      path: 'sprites/arena.png',
                                      anchor_x: 0.5,
                                      anchor_y: 0.5 }

      outputs.primitives << {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        path: :scene
      }
    end

    def scrolling_tiles(tile_size:, viewport_w:, viewport_h:,
                        dx:, dy:, tick_count:,
                        path:, a: 255)
      period = tile_size * 2
      x_offset = (tick_count * dx) % period
      y_offset = (tick_count * dy) % period

      cols = viewport_w.fdiv(tile_size).ceil + 2
      rows = viewport_h.fdiv(tile_size).ceil + 2

      cols.map do |cx|
        rows.map do |cy|
          {
            x: cx * tile_size + x_offset - period,
            y: cy * tile_size + y_offset - period,
            w: tile_size,
            h: tile_size,
            path: path,
            flip_horizontally: cx.even?,
            flip_vertically: cy.even?,
            a: a
          }
        end
      end
    end
  end

  DR.reset

```
