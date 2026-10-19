### Checkboxes - main.rb
```ruby
  # ./samples/09_ui_controls/01_checkboxes/app/main.rb
  def boot args
    # initialize args.state to an empty hash on boot
    args.state = {}
  end

  def tick args
    defaults args
    calc args
    render args
  end

  def defaults args
    # animation duration of the checkbox (15 frames/quarter of a second)
    args.state.checkbox_animation_duration ||= 15

    # use layout apis to position check boxes
    # set the time the checkbox was changed to "the past" so it shows up immediately on load
    args.state.checkboxes ||= [
      Layout.rect(row: 0, col: 0, w: 1, h: 1)
            .merge(id: :option_1, text: "Option 1", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 1, col: 0, w: 1, h: 1)
            .merge(id: :option_2, text: "Option 2", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 2, col: 0, w: 1, h: 1)
            .merge(id: :option_3, text: "Option 3", checked: false, changed_at: -args.state.checkbox_animation_duration),
      Layout.rect(row: 3, col: 0, w: 1, h: 1)
            .merge(id: :option_4, text: "Option 4", checked: false, changed_at: -args.state.checkbox_animation_duration),
    ]

    # if it's the first tick, then load checkbox state from save file
    if Kernel.tick_count == 0
      load_checkbox_state args.state.checkboxes
    end
  end

  def calc args
    return if !args.inputs.mouse.click

    # see if any checkboxes were checked
    clicked_checkbox = args.state.checkboxes.find do |checkbox|
      Geometry.inside_rect? args.inputs.mouse, checkbox
    end

    # if no checkboxes were clicked, return
    return if !clicked_checkbox

    # toggle the checkbox's checked state and mark when it was checked
    clicked_checkbox.checked = !clicked_checkbox.checked
    clicked_checkbox.changed_at = Kernel.tick_count

    # save checkbox state to file
    save_checkbox_state args.state.checkboxes
  end

  def render args
    # render checkboxes using the checkbox_prefab function
    args.outputs.primitives << args.state.checkboxes.map do |checkbox|
      checkbox_prefab checkbox, args.state.checkbox_animation_duration
    end
  end

  def checkbox_prefab checkbox, animation_duration
    # this is the visuals for the checkbox

    # compute the location of the label
    label = {
      x: checkbox.x + checkbox.w + 8,
      y: checkbox.center.y,
      text: checkbox.text,
      anchor_x: 0.0,
      anchor_y: 0.5,
      size_px: 22
    }

    # this represents the checkbox area
    border = {
      x: checkbox.x, y: checkbox.y, w: checkbox.w, h: checkbox.h,
      r: 200, g: 200, b: 200,
      path: :solid
    }

    # determine the check state fade in/fade out percentage
    # use the checkbox.changed_at to determine the percentage
    animation_percentage = if checkbox.checked
                             Easing.smooth_stop(start_at: checkbox.changed_at,
                                                duration: animation_duration,
                                                tick_count: Kernel.tick_count,
                                                power: 4,
                                                flip: false)
                           else
                             Easing.smooth_stop(start_at: checkbox.changed_at,
                                                duration: animation_duration,
                                                tick_count: Kernel.tick_count,
                                                power: 4,
                                                flip: true)
                           end

    # using the percentage that was calculated, and
    # render a solid that represents the checkbox's "checked" indicator
    indicator = {
      x: checkbox.center.x,
      y: checkbox.center.y,
      w: (checkbox.w / 2) * animation_percentage,
      h: (checkbox.h / 2) * animation_percentage,
      anchor_x: 0.5,
      anchor_y: 0.5,
      path: :solid,
      r: 0, g: 0, b: 0,
      a: animation_percentage * 255
    }

    # render the labe, border, and indicator
    [
      label,
      border,
      indicator,
    ]
  end

  def save_checkbox_state checkboxes
    # create the save data in the format of id,checked
    # eg:
    #   option_1,true
    #   option_2,false
    #   option_3,false
    #   option_4,false
    content = checkboxes.map do |c|
      "#{c.id},#{c.checked}"
    end.join "\n"

    # write the contents to data/checkbox-state.txt
    DR.write_file "data/checkbox-state.txt", content
  end

  def load_checkbox_state checkboxes
    # read the save file
    content = DR.read_file "data/checkbox-state.txt"

    # if it doesn't exist then return
    return if !content

    # eg:
    #   option_1,true
    #   option_2,false
    #   option_3,false
    #   option_4,false
    # becomes:
    #   results = {
    #     option_1: true,
    #     option_2: false,
    #     option_3: false,
    #     option_4: false,
    #   }
    results = { }

    # each line has the id of the checkbox, and its value
    content.each_line do |l|
      # get the tokens split on commas for the line
      tokens = l.strip.split(",")

      # the first token is the id of the checkbox
      id = tokens[0].to_sym

      # the second value is the check state
      checked = tokens[1] == "true"

      # store values in the results lookup
      results[id] = checked
    end

    # after the results have been parsed from the file,
    # go through the checkboxes and set their checked value to
    # what was found in the file
    checkboxes.each do |c|
      c.checked = results[c.id]
    end
  end

```

### Toggle Button - main.rb
```ruby
  # ./samples/09_ui_controls/01_toggle_button/app/main.rb
  class ToggleButton
    attr :on_off

    def initialize(x:, y:, w:, h:, on_off:, button_text:, on_click:)
      @x = x
      @y = y
      @w = w
      @h = h
      @on_off = on_off
      @button_text = button_text
      @on_click = on_click
    end

    def prefab
      color = if @on_off
                { r: 255, g: 255, b: 255 }
              else
                { r: 128, g: 128, b: 128 }
              end
      [
        { x: @x,
          y: @y,
          w: @w,
          h: @h,
          path: :solid,
          r: 30,
          g: 30,
          b: 30 },
        { x: @x + @w / 2,
          y: @y + @h / 2,
          text: "#{@button_text.call(@on_off)}",
          anchor_x: 0.5,
          anchor_y: 0.5,
          **color },
      ]
    end

    def click_rect
      { x: @x, y: @y, w: @w, h: @h }
    end

    def tick inputs
      if inputs.mouse.click && inputs.mouse.inside_rect?(click_rect)
        @on_off = !@on_off
        @on_click.call(@on_off)
      end
    end
  end

  def tick args
    init_state args
    args.state.buttons.each { |button| button.tick args.inputs }
    args.outputs.primitives << args.state.buttons.map { |button| button.prefab }
  end

  def init_state args
    return if Kernel.tick_count != 0

    args.state.game_speed  ||= :slow
    args.state.color_theme ||= :dark
    args.state.bg_music    ||= :unmuted
    game_speed_button = ToggleButton.new(x: 8,
                                         y: 720 - 32 - 8,
                                         w: 512,
                                         h: 32,
                                         on_off: true,
                                         button_text: lambda { |on_off|
                                           "Game Speed: #{args.state.game_speed} (on_off state: #{on_off})"
                                         },
                                         on_click: lambda { |on_off|
                                           if on_off
                                             args.state.game_speed = :fast
                                           else
                                             args.state.game_speed = :slow
                                           end
                                         })

    game_color_theme_button = ToggleButton.new(x: 8,
                                               y: 720 - 64 - 16,
                                               w: 512,
                                               h: 32,
                                               on_off: true,
                                               button_text: lambda { |on_off|
                                                 "Color Theme: #{args.state.color_theme} (on_off state: #{on_off})"
                                               },
                                               on_click: lambda { |on_off|
                                                 if on_off
                                                   args.state.color_theme = :dark
                                                 else
                                                   args.state.color_theme = :light
                                                 end
                                               })

    bg_music_button = ToggleButton.new(x: 8,
                                       y: 720 - 96 - 24,
                                       w: 512,
                                       h: 32,
                                       on_off: true,
                                       button_text: lambda { |on_off|
                                         "Background Music: #{args.state.bg_music} (on_off state: #{on_off})"
                                       },
                                       on_click: lambda { |on_off|
                                         if on_off
                                           args.state.bg_music = :unmuted
                                         else
                                           args.state.bg_music = :muted
                                         end
                                       })

    args.state.buttons = [
      game_speed_button,
      game_color_theme_button,
      bg_music_button,
    ]
  end

  DR.reset

```

### Menu Navigation - main.rb
```ruby
  # ./samples/09_ui_controls/02_menu_navigation/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def render
      outputs.primitives << state.selection_point.merge(w: state.menu.button_w + 8,
                                                        h: state.menu.button_h + 8,
                                                        a: 128,
                                                        r: 0,
                                                        g: 200,
                                                        b: 100,
                                                        path: :solid,
                                                        anchor_x: 0.5,
                                                        anchor_y: 0.5)

      outputs.primitives << state.menu.buttons.map(&:primitives)
    end

    def calc_directional_input
      return if state.input_debounce.elapsed_time < 10
      return if !inputs.directional_vector
      state.input_debounce = Kernel.tick_count

      state.selected_button = Geometry::rect_navigate(
        rect: state.selected_button,
        rects: state.menu.buttons,
        left_right: inputs.left_right,
        up_down: inputs.up_down,
        wrap_x: true,
        wrap_y: true,
        using: lambda { |e| e.rect }
      )
    end

    def calc_mouse_input
      return if !inputs.mouse.moved
      hovered_button = state.menu.buttons.find { |b| Geometry::intersect_rect? inputs.mouse, b.rect }
      if hovered_button
        state.selected_button = hovered_button
      end
    end

    def calc
      target_point = state.selected_button.rect.center
      state.selection_point.x = state.selection_point.x.lerp(target_point.x, 0.25)
      state.selection_point.y = state.selection_point.y.lerp(target_point.y, 0.25)
      calc_directional_input
      calc_mouse_input
    end

    def defaults
      if !state.menu
        state.menu = {
          button_cell_w: 2,
          button_cell_h: 1,
        }
        state.menu.button_w = Layout::rect(w: 2).w
        state.menu.button_h = Layout::rect(h: 1).h
        state.menu.buttons = [
          menu_prefab(id: :item_1, text: "Item 1", row: 0, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_2, text: "Item 2", row: 0, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_3, text: "Item 3", row: 0, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_4, text: "Item 4", row: 1, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_5, text: "Item 5", row: 1, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_6, text: "Item 6", row: 1, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_7, text: "Item 7", row: 2, col: 0, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_8, text: "Item 8", row: 2, col: 2, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
          menu_prefab(id: :item_9, text: "Item 9", row: 2, col: 4, w: state.menu.button_cell_w, h: state.menu.button_cell_h),
        ]
      end

      state.selected_button ||= state.menu.buttons.first
      state.selection_point ||= { x: state.selected_button.rect.center.x,
                                  y: state.selected_button.rect.center.y }
      state.input_debounce  ||= 0
    end

    def menu_prefab id:, text:, row:, col:, w:, h:;
      rect = Layout::rect(row: row, col: col, w: w, h: h)
      {
        id: id,
        row: row,
        col: col,
        text: text,
        rect: rect,
        primitives: [
          rect.merge(primitive_marker: :border),
          rect.center.merge(text: text, anchor_x: 0.5, anchor_y: 0.5)
        ]
      }
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Menu Navigation Advanced - main.rb
```ruby
  # ./samples/09_ui_controls/02_menu_navigation_advanced/app/main.rb
  class Game
    attr_dr

    def initialize
      # items to render within the menu
      @items = [
        { id: :bow, },
        { id: :boomerang, },
        { id: :hookshot, },
        { id: :bomb, },
        { id: :powder, },
        { id: :pot_1, },
        { id: :fire_rod, },
        { id: :ice_rod, },
        { id: :ether, },
        { id: :quake, },
        { id: :bombos, },
        { id: :pot_2, },
        { id: :lantern, },
        { id: :hammer, },
        { id: :flute, },
        { id: :net, },
        { id: :mudora, },
        { id: :pot_3, },
        { id: :shovel, },
        { id: :somaria, },
        { id: :bryna, },
        { id: :cape, },
        { id: :mirror, },
        { id: :pot3, },
        { id: :boots, },
        { id: :mitt, },
        { id: :flippers, },
        { id: :pearl, },
      ]

      # compute the menu location for each item and capture the rect
      # along with generating the prefab
      @items.each_with_index do |item, i|
        row = i.idiv(6)
        col = i % 6
        item.click_box = Layout.rect(row: 1 + row * 2, col: 0.50 + col * 2.5, w: 2, h: 2)
        item.prefab = [
          item.click_box.merge(path: :solid, r: 0, g: 0, b: 0),
          item.click_box.center.merge(text: "#{item.id}", r: 255, g: 255, b: 255, anchor_x: 0.5, anchor_y: 0.5)
        ]
      end
    end

    def tick
      calc
      render
    end

    def calc
      # set the hovered item to the first item
      @hovered_item ||= @items.first

      if inputs.last_active == :mouse
        # if the mouse is used, then recompute the hovered item
        # using the mouse location
        moused_item = @items.find { |item| Geometry.inside_rect? inputs.mouse, item.click_box }

        # if the mouse is over an item, then set it
        # as the new hovered item, otherwise keep the current selection
        @hovered_item = moused_item || @hovered_item

        # if mouse is clicked then select the item
        if inputs.mouse.click && @hovered_item
          item_selected! @hovered_item
        end
      else
        # if controller or keyboard is the last active input
        # then use Geometry.rect_navigate to select the item
        @hovered_item = Geometry.rect_navigate(rect: @hovered_item,
                                               rects: @items,
                                               left_right: inputs.key_down.left_right,
                                               up_down: inputs.key_down.up_down,
                                               using: :click_box)

        # if enter (keyboard) or A (controller) is pressed, then select the item
        if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.a
          item_selected! @hovered_item
        end
      end
    end

    # item selection logic would go here
    def item_selected! item
      DR.notify "#{item.id} was selected."
    end

    def render
      outputs.background_color = [30, 30, 30]

      # Layout apis used to create the item menu
      # main items section
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 0, w: 15.5, h: 12)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 0, w: 15, h: 1)
                                                .center
                                                .merge(text: "Items",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      outputs[:items_popup].primitives << @items.map(&:prefab)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 15.5, w: 8.5, h: 3)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 0, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Pendants",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 3, col: 15.5, w: 8.5, h: 3)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 3, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Crystals",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # example of using Layout to create other sections
      outputs[:items_popup].primitives << Layout.rect(row: 6, col: 15.5, w: 8.5, h: 6)
                                                .merge(path: :solid, r: 255, g: 255, b: 255, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 6, col: 15.5, w: 8.5, h: 1)
                                                .center
                                                .merge(text: "Equipment",
                                                       anchor_x: 0.5,
                                                       anchor_y: 0.5,
                                                       size_px: 48)

      # render the current hovered item indicator and label
      outputs[:items_popup].primitives << @hovered_item.click_box.merge(path: :solid, r: 0, g: 160, b: 0, a: 128)
      outputs[:items_popup].primitives << Layout.rect(row: 11, col: 0, w: 15.5, h: 1)
                                                .center
                                                .merge(text: "Hovered Item: #{@hovered_item.id}", anchor_x: 0.5, anchor_y: 0.5)

      # fade and slide in animation
      perc = Easing.smooth_stop(start_at: 0,
                                duration: 90,
                                tick_count: Kernel.tick_count,
                                power: 3)

      outputs.primitives << { x: 0,
                              y: (1 - perc) * 1280,
                              w: 1280,
                              h: 720,
                              a: 255 * perc,
                              path: :items_popup }
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Radial Menu - main.rb
```ruby
  # ./samples/09_ui_controls/03_radial_menu/app/main.rb
  class Game
    attr_dr

    def tick
      defaults
      calc
      render
    end

    def defaults
      state.menu_items = [
        { id: :item_1, text: "Item 1" },
        { id: :item_2, text: "Item 2" },
        { id: :item_3, text: "Item 3" },
        { id: :item_4, text: "Item 4" },
        { id: :item_5, text: "Item 5" },
        { id: :item_6, text: "Item 6" },
        { id: :item_7, text: "Item 7" },
        { id: :item_8, text: "Item 8" },
        { id: :item_9, text: "Item 9" },
      ]

      state.menu_status     ||= :hidden
      state.menu_radius     ||= 200
      state.menu_status_at  ||= -1000
    end

    def calc
      state.menu_items.each_with_index do |item, i|
        item.menu_angle = 90 + (360 / state.menu_items.length) * i
        item.menu_angle_range = 360 / state.menu_items.length - 10
      end

      state.menu_items.each do |item|
        item.rect = Geometry.rect_props x: 640 + item.menu_angle.vector_x * state.menu_radius - 50,
                                        y: 360 + item.menu_angle.vector_y * state.menu_radius - 25,
                                        w: 100,
                                        h: 50

        item.circle = { x: item.rect.x + item.rect.w / 2, y: item.rect.y + item.rect.h / 2, radius: item.rect.w / 2 }
      end

      show_menu_requested = false
      if state.menu_status == :hidden
        show_menu_requested = true if inputs.controller_one.key_down.a
        show_menu_requested = true if inputs.mouse.click
      end

      hide_menu_requested = false
      if state.menu_status == :shown
        hide_menu_requested = true if inputs.controller_one.key_down.b
        hide_menu_requested = true if inputs.mouse.click && !state.hovered_menu_item
      end

      if state.menu_status == :shown && state.hovered_menu_item && (inputs.mouse.click || inputs.controller_one.key_down.a)
        DR.notify! "You selected #{state.hovered_menu_item[:text]}"
      elsif show_menu_requested
        state.menu_status = :shown
        state.menu_status_at = Kernel.tick_count
      elsif hide_menu_requested
        state.menu_status = :hidden
        state.menu_status_at = Kernel.tick_count
      end

      state.hovered_menu_item = state.menu_items.find { |item| Geometry.point_inside_circle? inputs.mouse, item.circle }

      if inputs.controller_one.active && inputs.controller_one.left_analog_active?(threshold_perc: 0.5)
        state.hovered_menu_item = state.menu_items.find do |item|
          Geometry.angle_within_range? inputs.controller_one.left_analog_angle, item.menu_angle, item.menu_angle_range
        end
      end
    end

    def menu_prefab item, perc
      dx = item.rect.center.x - 640
      x = 640 + dx * perc
      dy = item.rect.center.y - 360
      y = 360 + dy * perc
      Geometry.rect_props item.rect.merge x: x - item.rect.w / 2, y: y - item.rect.h / 2
    end

    def ring_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x: x_center + radius * theta.cos_r,
          y: y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          **color
        }
      end
    end

    def circle_prefab x_center, y_center, radius, precision:, color: nil
      color ||= { r: 0, g: 0, b: 0, a: 255 }
      pi = Math::PI
      lines = []

      # Indie/Pro Only (uses triangles)
      precision.map do |i|
        theta = 2.0 * pi * i / precision
        next_theta = 2.0 * pi * (i + 1) / precision

        {
          x:  x_center + radius * theta.cos_r,
          y:  y_center + radius * theta.sin_r,
          x2: x_center + radius * next_theta.cos_r,
          y2: y_center + radius * next_theta.sin_r,
          y3: y_center,
          x3: x_center,
          source_x:  0,
          source_y:  0,
          source_x2: 0,
          source_y2: radius,
          source_x3: radius,
          source_y3: 0,
          path:      :solid,
          **color,
        }
      end
    end

    def render
      outputs.debug.watch "Controller"
      outputs.debug.watch pretty_format(inputs.controller_one.to_h)

      outputs.debug.watch "Mouse"
      outputs.debug.watch pretty_format(inputs.mouse.to_h)

      # outputs.debug.watch "Mouse"
      # outputs.debug.watch pretty_format(inputs.mouse)
      outputs.primitives << { x: 640, y: 360, w: 10, h: 10, path: :solid, r: 128, g: 0, b: 0, a: 128, anchor_x: 0.5, anchor_y: 0.5 }

      if state.menu_status == :shown
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart)
      else
        perc = Easing.ease(state.menu_status_at, Kernel.tick_count, 30, :smooth_stop_quart, :flip)
      end

      outputs.primitives << state.menu_items.map do |item|
        a = 255 * perc
        color = { r: 128, g: 128, b: 128, a: a }
        if state.hovered_menu_item == item
          color = { r: 80, g: 128, b: 80, a: a }
        end

        menu = menu_prefab(item, perc)

        if state.menu_status == :shown
          ring = ring_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
          circle = circle_prefab(menu.center.x, menu.center.y, item.circle.radius, precision: 30, color: color.merge(a: 128))
        end

        [
          ring,
          circle,
          menu.merge(path: :solid, **color),
          menu.center.merge(text: item.text, a: a, anchor_x: 0.5, anchor_y: 0.5)
        ]
      end
    end
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset
    $game = nil
  end

  DR.reset

```

### Scroll View - main.rb
```ruby
  # ./samples/09_ui_controls/03_scroll_view/app/main.rb
  require 'app/scroll_view.rb'

  module Main
    attr :sv_left, :sv_right

    def start
      sprite_paths = [
        "sprites/square/red.png",
        "sprites/square/orange.png",
        "sprites/square/yellow.png",
        "sprites/square/green.png",
        "sprites/square/blue.png",
        "sprites/square/indigo.png",
        "sprites/square/violet.png",
        "sprites/square/white.png",
        "sprites/square/black.png",
        "sprites/square/gray.png",
      ]

      @things_left = 51.map do |i|
        {
          name: "Item #{i}",
          price: Numeric.rand(10..100),
          path: sprite_paths.sample
        }
      end

      @things_right = 51.map do |i|
        {
          name: "Item #{i}",
          price: Numeric.rand(10..100),
          path: sprite_paths.sample
        }
      end

      @sv_left = ScrollView.new(
        row: 1,
        col: 1,
        w: 8,
        h: 10
      )

      build_sv @sv_left, @things_left

      @sv_right = ScrollView.new(
        row: 1,
        col: 15,
        w: 8,
        h: 10
      )

      build_sv @sv_right, @things_right
    end

    def build_sv sv, things
      scroll_y = sv.scroll_y
      sv.clear
      things.each do |t|
        sv.add w: 2,
               h: 2,
               text: [t.name, t.price],
               path: t.path,
               ref: t
      end
      sv.scroll_y = scroll_y
    end

    def switch_input_modes!
      @sv_left.scroll_to id: @sv_left.items.first.id
      @sv_right.scroll_to id: @sv_right.items.first.id
      @hovered_item_id = nil
      @active_sv = @sv_left
    end

    def move_item item_rect
      return if !item_rect
      DR.notify "Item moved: #{item_rect.item.text} #{item_rect.item.scroll_view_id}"
      if item_rect.item.scroll_view_id == @sv_left.id
        @things_left.reject! { |t| t == item_rect.item.ref }
        @things_right << item_rect.item.ref
        build_sv @sv_left, @things_left
        build_sv @sv_right, @things_right
        item = @sv_right.items.find { |i| i.ref == item_rect.item.ref }
        @sv_right.scroll_to id: item.id
        @hovered_item_id = @sv_left.find_item_rect(rect: item_rect.rect)&.item&.id
        @sv_left.scroll_to id: @hovered_item_id
      elsif item_rect.item.scroll_view_id == @sv_right.id
        @things_right.reject! { |t| t == item_rect.item.ref }
        @things_left << item_rect.item.ref
        build_sv @sv_left, @things_left
        build_sv @sv_right, @things_right
        item = @sv_left.items.find { |i| i.ref == item_rect.item.ref }
        @sv_left.scroll_to id: item.id
        @hovered_item_id = @sv_right.find_item_rect(rect: item_rect.rect)&.item&.id
        @sv_right.scroll_to id: @hovered_item_id
      end
    end

    def key_repeat_left_right
      if inputs.last_active == :keyboard
        inputs.keyboard.key_repeat.left_right
      else
        if inputs.controller_one.key_down.left_right != 0
          inputs.controller_one.left_right
        elsif (inputs.controller_one.key_held.left || inputs.controller_one.key_held.right)
          t = inputs.controller_one.key_held.left || inputs.controller_one.key_held.right
          if t.elapsed_time > 12 && t.elapsed_time.zmod?(2)
            inputs.controller_one.left_right
          else
            0
          end
        else
          0
        end
      end
    end

    def key_repeat_up_down
      if inputs.last_active == :keyboard
        inputs.keyboard.key_repeat.up_down
      else
        if inputs.controller_one.key_down.up_down != 0
          inputs.controller_one.up_down
        elsif (inputs.controller_one.key_held.up || inputs.controller_one.key_held.down)
          t = inputs.controller_one.key_held.up || inputs.controller_one.key_held.down
          if t.elapsed_time > 12 && t.elapsed_time.zmod?(2)
            inputs.controller_one.up_down
          else
            0
          end
        else
          0
        end
      end
    end

    def calc_buy_mouse
      if inputs.mouse.intersect_rect?(@sv_left.rect)
        @active_sv = @sv_left
      elsif inputs.mouse.intersect_rect?(@sv_right.rect)
        @active_sv = @sv_right
      end

      @sv_left.tick_mouse inputs.mouse
      @sv_right.tick_mouse inputs.mouse
      @hovered_item_id = @sv_left.hovered_item(inputs.mouse)&.item&.id ||
                         @sv_right.hovered_item(inputs.mouse)&.item&.id

      move_item(@sv_left.clicked_item(inputs.mouse) || @sv_right.clicked_item(inputs.mouse))
    end

    def calc_buy_keyboard
      return if @sv_left.items.length == 0 && @sv_right.items.length == 0

      if @sv_left.items.length == 0 && !@hovered_item_id
        @active_sv = @sv_right
        @hovered_item_id = @active_sv.items_rects.first&.item&.id
        @active_sv.scroll_to id: @hovered_item_id
      elsif @sv_right.items.length == 0 && !@hovered_item_id
        @active_sv = @sv_left
        @hovered_item_id = @active_sv.items_rects.first&.item&.id
        @active_sv.scroll_to id: @hovered_item_id
      end

      @hovered_item_id ||= @sv_left.items_rects.first&.item&.id
      prev_id = @hovered_item_id
      nav_rects = if key_repeat_left_right != 0
                    @sv_left.items_rects + @sv_right.items_rects
                  else
                    @active_sv.items_rects
                  end

      hovered_rect = Geometry.rect_navigate(rect: @active_sv.find_item_rect(id: @hovered_item_id),
                                            rects: nav_rects,
                                            left_right: key_repeat_left_right,
                                            up_down: key_repeat_up_down,
                                            wrap_x: false,
                                            wrap_y: false,
                                            using: :rect)

      @hovered_item_id = hovered_rect.item.id

      if @hovered_item_id && @hovered_item_id != prev_id
        if hovered_rect.item.scroll_view_id == @sv_left.id
          @active_sv = @sv_left
        elsif hovered_rect.item.scroll_view_id == @sv_right.id
          @active_sv = @sv_right
        end

        @active_sv.scroll_to(id: @hovered_item_id)
      end

      @sv_left.tick_scroll_y
      @sv_right.tick_scroll_y

      if inputs.keyboard.key_down.enter || inputs.controller_one.key_down.s
        move_item @active_sv.find_item_rect(id: @hovered_item_id)
      end
    end

    def tick
      $outputs.watch "#{DR.current_framerate}"

      @active_sv ||= @sv_left

      if inputs.last_active_at == Kernel.tick_count - 1
        switch_input_modes!
      else
        if inputs.last_active == :mouse
          calc_buy_mouse
        elsif inputs.last_active == :keyboard || inputs.last_active == :controller
          calc_buy_keyboard
        end
      end

      render
    end

    def render
      outputs[@sv_left.id].set w: @sv_left.content_rect.w,
                               h: @sv_left.content_rect.h,
                               background_color: [0, 0, 0, 0]

      outputs[@sv_left.id].primitives << @sv_left.primitives

      outputs[@sv_right.id].set w: @sv_right.content_rect.w,
                                h: @sv_right.content_rect.h,
                                background_color: [0, 0, 0, 0]

      outputs[@sv_right.id].primitives << @sv_right.primitives

      if @hovered_item_id
        if inputs.last_active == :mouse && !inputs.mouse.buttons.left.buffered_held && !inputs.mouse.wheel
          item_rect = @sv_left.find_item_rect(id: @hovered_item_id) ||
                      @sv_right.find_item_rect(id: @hovered_item_id)
          outputs[@active_sv.id].primitives <<  {
            **item_rect.content_rect,
            path: :solid,
            r: 255, g: 255, b: 255, a: 128
          }
        elsif (inputs.last_active == :keyboard || inputs.last_active == :controller) && !@active_sv.target_scroll_y
          item_rect = @sv_left.find_item_rect(id: @hovered_item_id) ||
                      @sv_right.find_item_rect(id: @hovered_item_id)
          if item_rect
            outputs[@active_sv.id].primitives <<  {
              **item_rect.content_rect,
              path: :solid,
              r: 255, g: 255, b: 255, a: 128
            }
          end
        end
      end


      outputs.background_color = [0, 0, 0, 0]

      outputs.primitives << { **@sv_left.rect, path: @sv_left.id }
      outputs.primitives << { **@sv_right.rect, path: @sv_right.id }

      # outputs.primitives << Layout.debug_primitives(a: 128, invert_colors: true)
    end
  end

  DR.reboot

```

### Scroll View - scroll_view.rb
```ruby
  # ./samples/09_ui_controls/03_scroll_view/app/scroll_view.rb
  # # example of how to roll your own scroll view
  # # copypasta this code into your game and customize as needed
  class ScrollView
    # a UUID represented as a string that uniquely identifies this
    # scroll view
    attr :id

    # the layout that the scroll view was initialized with
    # can be passed into Layout.rect, eg: Layout.rect(**@scroll_view.layout)
    attr :layout

    # the rect of the scroll view in the
    # screen
    attr :rect

    # the content layout that the scroll view was initialized with
    # can be passed into Layout.rect, eg: Layout.rect(**@scroll_view.content_layout)
    attr :content_layout

    # the rect of the scroll view content
    # (aligned to 0, 0 -> Hash[x: 0, y: 0, w: 320, h: 320])
    attr :content_rect

    # the layout representing the size of a single row
    # with origin a 0, 0
    # can be passed into Layout.rect, eg: Layout.rect(**@scroll_view.row_layout)
    attr :row_layout

    # the rect of a single row
    # (aligned to 0, 0 -> Hash[x: 0, y: 0, w: 320, h: 320])
    attr :row_rect

    # the current location of the where the content has
    # been scrolled to
    attr :scroll_y

    # the scroll_y location that the scroll view should
    # lerp to (if set)
    attr :target_scroll_y

    # inertia of scroll view, scroll way is incremented by this value
    # and then dy is dampened by 5%
    attr :dy

    # Array of Hash with the following properties:
    # Hash[
    #   :id,             # UUID
    #   :index,          # int
    #   :highlighted,    # boolean
    #   :scroll_view_id, # UUID
    #   :text,           # Array of String that is used for primitives rendering
    #   :path            # item background sprite used for primitives rendering
    #   :layout          # Hash[:w, :h] (partial Layout.rect information)
    #   :ref             # Reference to the source object the item was derived from
    # ]
    attr :items

    # parameters to the constructor represents the location on
    # the screen that you want to render the scroll view to
    def initialize(row:, col:, w:, h:)
      @id = DR.create_uuid
      @layout = {
        row: row, col: col,
        w: w, h: h,
        include_gutter: true,
      }

      @content_layout = {
        row: 0, col: 0,
        w: w, h: h,
        include_gutter: true,
        origin: :bottom_left,
        safe_area: false
      }

      @row_layout = {
        row: 0, col: 0,
        w: w, h: 1,
        include_gutter: false,
        origin: :bottom_left,
        safe_area: false
      }

      @rect = Layout.rect(**@layout)
      @content_rect = Layout.rect(**@content_layout)
      @row_rect = Layout.rect(**@row_layout)

      @items = []
      @scroll_y = 0
      @dy = 0
    end

    # function adds an item to the scroll view,
    # items will be auto filled left to right,
    # top to bottom
    def add(w:, h:, text:, path:, ref:)
      @items << {
        id: DR.create_uuid,
        index: @items.length,
        highlighted: false,
        highlighted_at: nil,
        scroll_view_id: @id,
        text: text.is_a?(Array) ? text : [text],
        path: path,
        layout: {
          w: w,
          h: h,
          origin: :bottom_left,
          safe_area: false
        }.freeze,
        ref: ref
      }.freeze
    end

    def content_h
      rects = items_rects.sort_by { |ir| ir.rect.y }
                         .map(&:rect)

      return 0 if rects.length == 0

      (rects.first.y - rects.last.y).abs + rects.first.h + Layout.gutter
    end

    def max_scroll_y
      content_h - @rect.h + Layout.gutter
    end

    def min_scroll_y
      0
    end

    # gets the layout args for each item
    # in the context of the content rect (origin bottom left, 0, 0)
    # returns Hash[:layout, :item, :rect]
    def items_rects
      curr_row = @layout.h - 1
      curr_col = 0
      prev_item_h = nil
      @items.map do |item|
        if curr_col + item.layout.w > @content_layout.w
          curr_row -= prev_item_h || item.layout.h
          curr_col = 0
          prev_item_h = nil
        end

        prev_item_h = Numeric.max(prev_item_h, item.layout.h)

        item_layout = {
          **item.layout,
          row: curr_row - (item.layout.h - 1),
          col: curr_col,
        }

        layout_rect = Layout.rect(**item_layout)
        content_rect = Geometry.rect(**layout_rect, y: layout_rect.y + @scroll_y)
        rect = Geometry.rect(**layout_rect,
                             x: layout_rect.x + @rect.x,
                             y: layout_rect.y + @rect.y + @scroll_y)

        curr_col += item_layout.w

        {
          layout: item_layout,
          item: item,
          rect: rect,
          layout_rect: layout_rect,
          content_rect: content_rect
        }
      end
    end

    def find_item_rect(id: nil, rect: nil)
      return nil if !id && !rect
      if id
        items_rects.find { |ir| ir.item.id == id }
      elsif rect
        rect = Geometry.rect rect
        items_rects.sort_by { |ir| Geometry.distance_squared(rect, ir.rect) }
                   .first
      end
    end

    def hovered_item mouse
      return nil if !Geometry.intersect_rect?(mouse, @rect)

      Geometry.find_intersect_rect(
        mouse,
        visible_rects,
        using: :rect
      )
    end

    def clicked_item mouse
      return nil if !mouse.buttons.left.buffered_click

      hovered_item mouse
    end

    def visible_rects
      Geometry.find_all_intersect_rect(
        { content_rect: @content_rect },
        items_rects,
        using: :content_rect
      )
    end

    def clear
      @items.clear
    end

    def scroll_row d_row
      @target_scroll_y ||= @scroll_y
      @target_scroll_y += (Layout.rect(**@row_layout, h: d_row.abs).h + Layout.gutter) * d_row.sign * -1
      @target_scroll_y = @target_scroll_y.clamp(min_scroll_y, max_scroll_y)
    end

    def scroll_to(id:)
      item_rect = items_rects.find { |ir| ir.item.id == id }
      return if !item_rect
      return if Geometry.intersect_rect? item_rect.content_rect, @content_rect
      if item_rect
        if item_rect.content_rect.y < 0
          @target_scroll_y = @scroll_y + item_rect.content_rect.y * -1 + Layout.gutter
        else
          @target_scroll_y = @scroll_y + (item_rect.content_rect.y * -1) +
                             (@content_rect.h - item_rect.content_rect.h) - Layout.gutter
        end
      end
    end

    def tick_scroll_y mouse = nil
      if @target_scroll_y
        @dy = 0
        @scroll_y = @scroll_y.lerp @target_scroll_y, 0.5 ** 2, tolerance: 4
        if @scroll_y.round(4) == @target_scroll_y.round(4)
          @scroll_y = @target_scroll_y
          @target_scroll_y = nil
        end
      end

      @scroll_y += @dy
      @dy *= 0.95
      @dy = @dy.round(4)
      if @dy.abs <= 0.5 && @dy != 0
        @dy = 0
        @scroll_y = @scroll_y.round
      end

      if @scroll_y <= min_scroll_y && ((mouse && !mouse.buttons.left.buffered_held && !mouse.wheel) || !mouse)
        @target_scroll_y = nil
        @scroll_y = @scroll_y.lerp(min_scroll_y, 0.1, tolerance: 1)
        @dy = 0
      elsif @scroll_y >= max_scroll_y && ((mouse && !mouse.buttons.left.buffered_held && !mouse.wheel) || !mouse)
        @target_scroll_y = nil
        @scroll_y = @scroll_y.lerp(max_scroll_y, 0.1, tolerance: 1)
        @dy = 0
      end
    end

    def tick_mouse mouse
      tick_scroll_y mouse
      tick_mouse_wheel mouse
      tick_mouse_held mouse
    end

    def tick_mouse_wheel mouse
      return nil if !Geometry.intersect_rect?(mouse, @rect)
      return nil if !mouse.wheel

        perc = if @scroll_y < min_scroll_y
                 (1 - (min_scroll_y - @scroll_y).abs / @rect.h) ** 4
               elsif @scroll_y > max_scroll_y
                 (1 - (max_scroll_y - @scroll_y).abs / @rect.h) ** 4
               else
                 1
               end

      if mouse.wheel.inverted
        @dy -= mouse.wheel.y * perc
      else
        @dy += mouse.wheel.y * perc
      end
    end

    def tick_mouse_held mouse
      return if !Geometry.intersect_rect?(mouse, @rect)
      return if !mouse.buttons.left.buffered_held

      if mouse.buttons.left.buffered_held.created_at == Kernel.tick_count
        @dy = 0
      else
        perc = if @scroll_y < min_scroll_y
                 (1 - (min_scroll_y - @scroll_y).abs / @rect.h) ** 4
               elsif @scroll_y > max_scroll_y
                 (1 - (max_scroll_y - @scroll_y).abs / @rect.h) ** 4
               else
                 1
               end
        @dy = mouse.relative_y * perc
      end
    end

    def items_primitives
      visible_rects.map do |vr|
        item = vr.item
        text = vr.item.text
        [
          { **vr.content_rect, path: vr.item.path },
          {
            **vr.content_rect.center,
            w: vr.content_rect.w - 16,
            h: vr.item.text.length * 28 + 4,
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0, g: 0, b: 0,
            path: :solid
          },
          String.line_anchors(text).map do |anchor, s|
            {
              **vr.content_rect.center,
              text: s,
              size_px: 22,
              anchor_x: 0.5,
              anchor_y: anchor,
              r: 255, g: 255, b: 255
            }
          end
        ]
      end
    end

    # primitives for the background of the scroll view
    def background_primitives
      {
        **@content_rect,
        path: :solid,
        r: 255, g: 255, b: 255, a: 255
      }
    end

    # all the primitives for the scroll view that
    # should be sent to a render target
    # Example rendering:
    # #+begin_src
    #  outputs[@scroll_view.id].set w: @scroll_view.rect.w,
    #                               h: @scroll_view.rect.h,
    #                               background_color: [0, 0, 0, 0]
    #
    #  outputs[@scroll_view.id].primitives << @scroll_view.primitives
    #  outputs.primitives << {
    #    **@scroll_view.rect,
    #    path: @scroll_view.id
    #  }
    #
    #  outputs.primitives << Layout.debug_primitives(a: 128, invert_colors: true)
    # #+end_src
    def primitives
      [
        background_primitives,
        items_primitives
      ]
    end
  end

  DR.reboot

```

### Accessiblity For The Blind - main.rb
```ruby
  # ./samples/09_ui_controls/04_accessiblity_for_the_blind/app/main.rb
  def tick args
    # create three buttons
    args.state.button_1 ||= { x: 0, y: 640, w: 100, h: 50 }
    args.state.button_1_label ||= { x: 50,
                                    y: 665,
                                    text: "button 1",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_2 ||= { x: 104, y: 640, w: 100, h: 50 }
    args.state.button_2_label ||= { x: 154,
                                    y: 665,
                                    text: "button 2",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    args.state.button_3 ||= { x: 208, y: 640, w: 100, h: 50 }
    args.state.button_3_label ||= { x: 258,
                                    y: 665,
                                    text: "button 3",
                                    anchor_x: 0.5,
                                    anchor_y: 0.5 }

    # create a label
    args.state.label_hello_world ||= { x: 640,
                                       y: 360,
                                       text: "hello world",
                                       anchor_x: 0.5,
                                       anchor_y: 0.5 }

    args.outputs.borders << args.state.button_1
    args.outputs.labels  << args.state.button_1_label

    args.outputs.borders << args.state.button_2
    args.outputs.labels  << args.state.button_2_label

    args.outputs.borders << args.state.button_3
    args.outputs.labels  << args.state.button_3_label

    args.outputs.labels  << args.state.label_hello_world

    # args.outputs.a11y is cleared every tick, internally the key
    # of the dictionary value is used to reference the interactable element.
    # the key can be a symbol or a string (everything get's converted to strings
    # beind the scenes)

    # =======================================
    # from the Console run DR.a11y_enable!
    # ctrl+r will disable a11y (or you can run DR.a11y_disable! in the console)
    # =======================================

    # with the a11y emulation enabled, you can only use left arrow, right arrow, and enter
    # when you press enter, DR converts the location to a mouse click
    args.outputs.a11y[:button_1] = {
      a11y_text: "button 1",
      a11y_trait: :button,
      x: args.state.button_1.x,
      y: args.state.button_1.y,
      w: args.state.button_1.w,
      h: args.state.button_1.h
    }

    args.outputs.a11y[:button_2] = {
      a11y_text: "button 2",
      a11y_trait: :button,
      x: args.state.button_2.x,
      y: args.state.button_2.y,
      w: args.state.button_2.w,
      h: args.state.button_2.h
    }

    args.outputs.a11y[:button_3] = {
      a11y_text: "button 3",
      a11y_trait: :button,
      x: args.state.button_3.x,
      y: args.state.button_3.y,
      w: args.state.button_3.w,
      h: args.state.button_3.h
    }

    args.outputs.a11y[:label_hello] = {
      a11y_text: "hello world",
      a11y_trait: :label,
      x: args.state.label_hello_world.x,
      y: args.state.label_hello_world.y,
      anchor_x: 0.5,
      anchor_y: 0.5,
    }

    # flash a notification for each respective button
    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_1)
      DR.notify_extended! message: "Button 1 clicked", a: 255
      # you can use a11y to speak information
      args.outputs.a11y["notify button clicked"] = {
        a11y_text: "button 1 clicked",
        a11y_trait: :notification
      }
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_2)
      DR.notify_extended! message: "Button 2 clicked", a: 255
    end

    if args.inputs.mouse.click && args.inputs.mouse.inside_rect?(args.state.button_3)
      DR.notify_extended! message: "Button 3 clicked", a: 255
      # you can also use a11y to redirect focus to another control
      args.outputs.a11y["notify button clicked"] = {
        a11y_trait: :notification,
        a11y_notification_target: :label_hello
      }
    end
  end

  DR.reset

```

### Animated Toggle Switch - main.rb
```ruby
  # ./samples/09_ui_controls/05_animated_toggle_switch/app/main.rb
  class ToggleSwitch
    attr :toggle_state

    def initialize(row:, col:, toggle_state: :left, on_click:)
      @click_rect = Layout.rect(row: row, col: col, w: 2, h: 1)
      @switch_rect = Layout.rect(row: row, col: col, w: 1, h: 1)
      left_x =  Layout.rect(row: row, col: col, w: 1, h: 1).x
      right_x = Layout.rect(row: row, col: col + 1, w: 1, h: 1).x
      @diff_x = right_x - left_x
      @animation_duration = 15
      @toggle_state = toggle_state
      @click_at = -@animation_duration
      @on_click = on_click
    end

    def prefab
      perc = if @toggle_state == :right
               Easing.smooth_stop(start_at: @click_at,
                                  duration: @animation_duration,
                                  tick_count: Kernel.tick_count,
                                  power: 4)
             elsif @toggle_state == :left
               Easing.smooth_stop(start_at: @click_at,
                                  duration: @animation_duration,
                                  tick_count: Kernel.tick_count,
                                  power: 4,
                                  flip: true)
             end

      text = if @toggle_state == :right
               "on"
             else
               "off"
              end

      switch_diff_x = @diff_x * perc

      switch_rect_prefab = [
        { **@switch_rect,
          path: :solid,
          r: 30,
          g: 30,
          b: 30,
          x: @switch_rect.x + switch_diff_x },
        { x: @switch_rect.x + 4 + switch_diff_x,
          y: @switch_rect.y + 4,
          w: @switch_rect.w - 8,
          h: @switch_rect.h - 8,
          path: :solid,
          r: 255,
          g: 255,
          b: 255 },
      ]

      switch_bg_prefab = { **@click_rect, path: :solid, r: 30, g: 30, b: 30 }

      switch_label_prefab = { **@switch_rect.center,
                              text: "#{text}",
                              anchor_x: 0.5,
                              anchor_y: 0.5,
                              r: 0,
                              g: 0,
                              b: 0,
                              x: @switch_rect.center.x + switch_diff_x }

      [
        switch_bg_prefab,
        switch_rect_prefab,
        switch_label_prefab,
      ]
    end

    def tick inputs
      return if !inputs.mouse.click
      return if !inputs.mouse.point.inside_rect?(@click_rect)

      if @toggle_state == :left
        @toggle_state = :right
        @click_at = Kernel.tick_count
      else
        @toggle_state = :left
        @click_at = Kernel.tick_count
      end

      @on_click.call @toggle_state
    end
  end

  class Game
    attr_dr

    def initialize
      @slide_toggle_buttons = [
        ToggleSwitch.new(row: 0,
                        col: 0,
                        toggle_state: :right,
                        on_click: lambda { |toggle_state| DR.notify "toggle 1 toggled to #{toggle_state}!" }),
        ToggleSwitch.new(row: 1,
                        col: 0,
                        toggle_state: :left,
                        on_click: lambda { |toggle_state| DR.notify "toggle 2 toggled to #{toggle_state}!" }),
      ]
    end

    def tick
      @slide_toggle_buttons.each { |btn| btn.tick inputs }
      outputs.primitives << @slide_toggle_buttons.map(&:prefab)
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Input Remapping - main.rb
```ruby
  # ./samples/09_ui_controls/06_input_remapping/app/main.rb
  # sample app demonstrates how you can create a UI for remapping inputs
  # for a controller/keyboard

  # wrapper game class so we aren't having to pass args.state everywhere
  class Game
    attr_dr # this class macro adds args.inputs, outputs, etc to Game

    def initialize
      # default input mappings for keyboard and controller one
      @input_mappings = {
        keyboard: {
          move_left: [:left_arrow],
          move_right: [:right_arrow]
        },
        controller_one: {
          move_left: [:left],
          move_right: [:right]
        }
      }

      # default the current input method to keyboard
      @current_input = :keyboard

      # set the current game mode to "playing the game" (ability to move the player)
      @mode = :game

      # initialized the player
      @player = {
        x: 640, y: 360, w: 80, h: 80,
        path: :solid,
        r: 80, g: 128, b: 128,
        anchor_x: 0.5,
        anchor_y: 0.5
      }
    end

    def tick
      # if the mode is game, then tick_game, otherwise tick_remap
      if @mode == :game
        tick_game
      elsif @mode == :remap
        tick_remap
      end

      # render remap_buttons
      args.outputs.primitives << remap_button_prefabs

      # render the player
      args.outputs.primitives << @player
    end

    def tick_game
      # determine what the current input is based on what was last used
      if args.inputs.last_active == :controller
        @current_input = :controller_one
      elsif args.inputs.last_active == :keyboard
        @current_input = :keyboard
      end

      # check the input mappings for the named action
      if activated? :move_left
        @player.x -= 5
      elsif activated? :move_right
        @player.x += 5
      end

      # if the mouse is used an the click intersects
      # with an input mapping button, then set the mode to "remapping mode"
      # capture which mapping will be updated
      if args.inputs.mouse.key_down.left
        button = remap_buttons.find { |b| args.inputs.mouse.inside_rect?(b.rect) }
        if button
          @mode = :remap
          @remap_input_name = button.input_name
          @remap_input_type = button.input_type
        end
      end
    end

    def tick_remap
      # if we are in remapping mode, get all keys that were pressed for
      # the input we are attempting to update
      keys = inputs.send(@remap_input_type).key_down.truthy_keys

      # if keys are returned, then update the mapping table with the new key alias
      # after updating the mapping, set the game back to "playing the game" mode
      if keys.length > 0
        @input_mappings[@remap_input_type][@remap_input_name] = keys
        @mode = :game
      end
    end

    # method returns true if the mapping for the pressed/held key, for the current input is true
    def activated? input_name
      # a reminder of what input mappings looks like:
      # @input_mappings = {
      #   keyboard: {
      #     move_left: [:left_arrow],
      #     move_right: [:right_arrow]
      #   },
      #   controller_one: {
      #     move_left: [:left],
      #     move_right: [:right]
      #   }
      # }
      @input_mappings[@current_input][input_name].any? { |k| inputs.send(@current_input).key_down_or_held?(k) }
    end

    def remap_buttons
      # create button information by traversing the current mapping
      @input_mappings.flat_map do |input_type, input_names|
        # .flat_map in combination with .map will give us a flattened list of buttons
        # from the input_mappings hash
        input_names.map do |input_name, input_keys|
          {
            input_keys: input_keys,
            input_type: input_type,
            input_name: input_name
          }
        end
      end.map_with_index do |h, i|
        # now that we have the hash with pertinant metadata,
        # use the Layout apis to generate rectagles (hit boxes) and text for the button
        {
          rect: Layout.rect(row: i, col: 0, w: 12, h: 1),
          text: "#{h.input_type} #{h.input_name}: #{h.input_keys}",
          **h
        }
      end
    end

    def remap_button_prefabs
      # take the rects from remap buttons and generate the
      # prefab
      remap_buttons.map do |b|
        # if the mode is "remapping mode", then change the color of the button
        # so we know which key we are attempting to remap
        color = if @mode == :remap && @remap_input_name == b.input_name && @remap_input_type == b.input_type
                  { r: 80, g: 80, b: 30 }
                else
                  { r: 30, g: 30, b: 30 }
                end
        [
          { **b.rect, path: :solid, **color }, # background border
          { **b.rect.center, text: "#{b.text}", anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255 } # text/label of the button
        ]
      end
    end
  end

  def boot args
    args.state = {}
  end

  def tick args
    $game ||= Game.new
    $game.args = args
    $game.tick
  end

  def reset args
    $game = nil
  end

  DR.reset

```

### Progress Bar - main.rb
```ruby
  # ./samples/09_ui_controls/07_progress_bar/app/main.rb
  def tick args
    args.outputs.background_color = [30, 30, 30]

    # track the max_hp, current_hp, and hp_perc (this is what we'll use to render remaining health)
    args.state.max_hp ||= 100
    args.state.current_hp ||= 100
    args.state.hp_perc ||= 1.0

    # every frame, lerp the hp_perc to current_hp / max_hp
    args.state.hp_perc = args.state.hp_perc.lerp(args.state.current_hp / args.state.max_hp, 0.1)

    # if j is pressed, or mouse is clicked, decrease the current hp (reset it if hp hits 0)
    if args.inputs.keyboard.key_down.enter || args.inputs.mouse.click
      if args.state.current_hp == 0
        args.state.current_hp = args.state.max_hp
      else
        args.state.current_hp -= 10
      end
    end

    args.outputs.labels << { x: 640,
                             y: 360 - 32,
                             text: "#{args.state.current_hp} / #{args.state.max_hp}",
                             anchor_x: 0.5,
                             anchor_y: 0.5,
                             r: 255, g: 255, b: 255 }

    # outer black border of the progress bar
    args.outputs.sprites << { x: 640 - 64,
                              y: 360,
                              w: 128,
                              h: 32,
                              path: :solid,
                              r: 0,
                              g: 0,
                              b: 0,
                              anchor_y: 0.5 }

    # inner white area of the progress bar
    args.outputs.sprites << { x: 640 - 62,
                              y: 360,
                              w: 124,
                              h: 28,
                              path: :solid,
                              r: 255,
                              g: 255,
                              b: 255,
                              anchor_y: 0.5 }

    # current health
    args.outputs.sprites << { x: 640 - 62,
                              y: 360,
                              w: 124 * args.state.hp_perc,
                              h: 28,
                              path: :solid,
                              r: 0,
                              g: 128,
                              b: 128,
                              anchor_y: 0.5 }
  end

```
