# 200 randomly placed circles. A click makes them spiral in to the click point
# and vanish under a background-colored cover; the next click sends them home
# in straight lines.
class Game
  attr_dr

  CIRCLE_COUNT = 200
  BACKGROUND_COLOR = [20, 20, 30]
  MIN_RADIUS = 6
  MAX_RADIUS = 20
  # Covers even the largest circle once it reaches the click point; the extra
  # 2 px keeps the soft edge of a same-sized circle from showing as a faint ring.
  HOLE_DIAMETER = MAX_RADIUS * 2 + 2
  # Each circle starts spiralling in a random 0 to SPIRAL_MAX_DELAY seconds
  # after the click.
  SPIRAL_MAX_DELAY = 0.5

  def tick
    defaults
    input
    calc
    render
  end

  def defaults
    state.circles ||= place_circles CIRCLE_COUNT
    # :home      - circles are at (or heading back to) their original positions
    # :gathering - circles are heading to the last click
    state.mode ||= :home
  end

  def input
    DR.request_quit if inputs.keyboard.key_down.escape

    return unless inputs.mouse.click

    if state.mode == :home
      gather_at inputs.mouse.x, inputs.mouse.y
    else
      send_home
    end
  end

  def calc
    state.circles.each(&:update)
  end

  def render
    outputs.background_color = BACKGROUND_COLOR
    outputs.sprites << state.circles
    # Drawn after the circles so it covers them, making them seem to vanish into it.
    if state.hole
      outputs.sprites << { x: state.hole.x - HOLE_DIAMETER / 2.0,
                           y: state.hole.y - HOLE_DIAMETER / 2.0,
                           w: HOLE_DIAMETER,
                           h: HOLE_DIAMETER,
                           path: 'sprites/solid-circle.png',
                           r: BACKGROUND_COLOR[0],
                           g: BACKGROUND_COLOR[1],
                           b: BACKGROUND_COLOR[2] }
    end
    outputs.labels << { x: 10, y: 710,
                        text: state.mode == :home ? 'Click to gather the circles' : 'Click to send them home',
                        r: 255, g: 255, b: 255 }
  end

  def gather_at x, y
    state.circles.each do |c|
      c.spiral_to x, y, delay: rand * SPIRAL_MAX_DELAY
    end
    state.hole = { x: x, y: y }
    state.mode = :gathering
    audio[:explosion] = nil
    audio[:suck] = { input: 'sounds/suck.wav' }
  end

  def send_home
    state.circles.each(&:return_home)
    state.hole = nil
    state.mode = :home
    audio[:suck] = nil
    audio[:explosion] = { input: 'sounds/explosion.wav' }
  end

  # Places circles one at a time, retrying random spots until each new circle
  # neither touches nor overlaps any circle already placed.
  def place_circles count, max_attempts: 1000
    circles = []
    count.times do
      attempts = 0
      candidate = random_circle
      while circles.any? { |c| c.touches? candidate }
        attempts += 1
        if attempts >= max_attempts
          puts "* WARNING: only room for #{circles.length} of #{count} circles."
          return circles
        end
        candidate = random_circle
      end
      circles << candidate
    end
    circles
  end

  def random_circle
    radius = MIN_RADIUS + rand(MAX_RADIUS - MIN_RADIUS + 1)
    CircleSprite.new(x: radius + rand(grid.w - radius * 2),
                     y: radius + rand(grid.h - radius * 2),
                     radius: radius,
                     speed: 2 + rand * 10)
  end
end
