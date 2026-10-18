# A circle rendered as a tinted sprite. The circle remembers where it was
# created (its "home") and can travel, in a straight line or a spiral, toward
# any point at its own speed.
class CircleSprite
  attr_sprite

  # Full turns a circle makes around the destination while spiralling in.
  SPIRAL_TURNS = 1
  # DragonRuby runs the simulation at a fixed 60 ticks per second.
  TICKS_PER_SECOND = 60

  attr_reader :speed

  # x, y   - center of the circle
  # radius - radius in pixels
  # speed  - pixels travelled per tick
  # color  - hash with :r, :g, :b (and optional :a); picked at random if nil
  def initialize(x:, y:, radius:, speed: 4, color: nil)
    @w = radius * 2
    @h = radius * 2
    @x = x - radius
    @y = y - radius
    @home_x = @x
    @home_y = @y
    @speed = speed
    @path = 'sprites/solid-circle.png'

    color ||= CircleSprite.random_color
    @r = color[:r]
    @g = color[:g]
    @b = color[:b]
    @a = color[:a] || 255
  end

  def self.random_color
    { r: rand(256), g: rand(256), b: rand(256) }
  end

  # Start travelling in a straight line so the circle's center ends up at (cx, cy).
  def move_to(cx, cy)
    @spiral_wait = nil
    @motion = :straight
    @target_x = cx - @w / 2
    @target_y = cy - @h / 2
  end

  # Spiral counterclockwise inward so the circle's center ends up at (cx, cy),
  # starting after `delay` seconds. Until then the circle carries on with
  # whatever it was doing (e.g. heading home), and the spiral begins from
  # wherever it is when the delay runs out.
  def spiral_to(cx, cy, delay: 0)
    @spiral_cx = cx
    @spiral_cy = cy
    @spiral_wait = (delay * TICKS_PER_SECOND).round
    start_spiral if @spiral_wait <= 0
  end

  # Start travelling in a straight line back to where the circle was created.
  def return_home
    @spiral_wait = nil
    @motion = :straight
    @target_x = @home_x
    @target_y = @home_y
  end

  def radius
    @w / 2
  end

  def center_x
    @x + radius
  end

  def center_y
    @y + radius
  end

  # True if the two circles overlap or touch (share even a single point).
  def touches?(other)
    dx = center_x - other.center_x
    dy = center_y - other.center_y
    reach = radius + other.radius
    dx * dx + dy * dy <= reach * reach
  end

  def moving?
    !@motion.nil? || !@spiral_wait.nil?
  end

  # Advance one tick along the current path, snapping on arrival.
  def update
    if @spiral_wait
      @spiral_wait -= 1
      start_spiral if @spiral_wait <= 0
    end

    case @motion
    when :straight then step_straight
    when :spiral   then step_spiral
    end
  end

  private

  def step_straight
    dx = @target_x - @x
    dy = @target_y - @y
    distance = Math.sqrt(dx * dx + dy * dy)

    if distance <= @speed
      @x = @target_x
      @y = @target_y
      @motion = nil
    else
      @x += dx / distance * @speed
      @y += dy / distance * @speed
    end
  end

  # The path is an Archimedean spiral: the distance to the destination shrinks
  # steadily with every radian turned, reaching zero after SPIRAL_TURNS.
  def start_spiral
    dx = center_x - @spiral_cx
    dy = center_y - @spiral_cy
    @spiral_wait = nil
    @motion = :spiral
    @spiral_distance = Math.sqrt(dx * dx + dy * dy)
    @spiral_angle = Math.atan2(dy, dx)
    # distance lost per radian turned
    @spiral_pitch = @spiral_distance / (2 * Math::PI * SPIRAL_TURNS)
  end

  # Moves @speed pixels along the spiral. On an Archimedean spiral an arc of
  # length ds spans d_angle = ds / sqrt(pitch^2 + distance^2) radians.
  def step_spiral
    if @spiral_distance > 0
      d_angle = @speed / Math.sqrt(@spiral_pitch * @spiral_pitch + @spiral_distance * @spiral_distance)
      @spiral_angle += d_angle
      @spiral_distance -= @spiral_pitch * d_angle
    end

    if @spiral_distance <= 0
      @x = @spiral_cx - radius
      @y = @spiral_cy - radius
      @motion = nil
    else
      @x = @spiral_cx + Math.cos(@spiral_angle) * @spiral_distance - radius
      @y = @spiral_cy + Math.sin(@spiral_angle) * @spiral_distance - radius
    end
  end
end
