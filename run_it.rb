require 'gosu'

class RunIt < Gosu::Window
  WINDOW_WIDTH  = 1280
  WINDOW_HEIGHT = 720

  MAX_JUMP_HEIGHT = 300.0
  PLAYER_X_POSITION = 300.0

  INITIAL_BACKGROUND_SPEED = 6.0
  MAX_BACKGROUND_SPEED = 17.0

  FLOOR_HEIGHT = 85.0
  FLOOR_Y = WINDOW_HEIGHT - FLOOR_HEIGHT

  MAX_OBSTACLES = 3
  OBSTACLES_MIN_DISTANCE = 750

  def initialize
    super(WINDOW_WIDTH, WINDOW_HEIGHT, false)

    self.caption = 'Run-it '

    @background = Background.new
    @player = Player.new
    @scoreboard = Scoreboard.new(@player)
    @obstacles = []
    @game_over_sign = GameOverSign.new
  end

  def update
    if self.game_over? && (Gosu::button_down?(Gosu::KbReturn) || Gosu::button_down?(Gosu::KbEnter))
      self.reset!
    end

    return if self.game_over?

    if Gosu::button_down?(Gosu::KbSpace)
      @player.jump!
    end

    @player.accelerate!
    @background.accelerate!

    @obstacles << Obstacle.new if self.add_obstacle?

    @player.move!
    @background.move!
    @obstacles.map { |obstacle| obstacle.move!(@background.vel_x) }
  end

  def game_over?
    on_player_obstacle = @obstacles.find(&:on_player_x?)

    on_player_obstacle && FLOOR_Y - on_player_obstacle.height < @player.y
  end

  def reset!
    @player.restart!
    @background.restart!
    @obstacles = []
  end

  def add_obstacle?
    return false if rand(100) >= 4 && @obstacles.size >= MAX_OBSTACLES

    !@obstacles.last || @obstacles.last.x <= WINDOW_WIDTH - OBSTACLES_MIN_DISTANCE
  end

  def draw
    @player.draw
    @background.draw
    @scoreboard.draw
    @obstacles.map(&:draw)
    @game_over_sign.draw if self.game_over?
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end

  class GameOverSign
    RESTART_TEXT = 'Press ENTER to restart'

    def initialize
      @font = Gosu::Font.new(50)
      @game_over_image = Gosu::Image.new('images/game_over.png')
    end

    def draw
      @game_over_image.draw_rot(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 0, 0)
      @font.draw(RESTART_TEXT, (WINDOW_WIDTH - @font.text_width(RESTART_TEXT)) / 2, 50, 0)
    end
  end

  class Scoreboard
    def initialize(player)
      @player = player
      @font = Gosu::Font.new(30)
    end

    def draw
      @font.draw("Score: #{@player.score}", 10, 10, 3, 1.0)
    end
  end

  class Obstacle
    TYPES = %w[big medium small]

    attr_reader :width, :height, :x

    def initialize
      @type = TYPES.sample
      @image = Gosu::Image.new("images/obstacles/#{@type}.png")
      @height = @image.height
      @width = @image.width
      @x = WINDOW_WIDTH
    end

    def on_screen?
      @x + @width >= 0
    end

    def on_player_x?
      ((self.x - @width)..self.x).include?(PLAYER_X_POSITION)
    end

    def move!(vel_x)
      @x += vel_x
    end

    def draw
      @image.draw_rot(@x, FLOOR_Y - (@height / 2), 0, 0)
    end
  end

  class Background
    attr_reader :vel_x

    def initialize
      @image = Gosu::Image.new('images/background.jpg', tileable: true)
      self.restart!
    end

    def restart!
      @x = 0
      @vel_x = -INITIAL_BACKGROUND_SPEED
    end

    def accelerate!
      @vel_x -= 0.03
      @vel_x = [@vel_x, -MAX_BACKGROUND_SPEED].max
    end

    def move!
      @x += @vel_x
      @x %= @image.width
    end

    def draw
      @image.draw(@x, 0, 0)
      @image.draw(@x - @image.width, 0, 0)
    end
  end

  class Player
    attr_accessor :score, :y

    def initialize
      @normal_image = Gosu::Image.new('images/player/normal.png')
      @jump_image = Gosu::Image.new('images/player/jump.png')
      @height = @normal_image.height
      self.restart!
    end

    def restart!
      @y = FLOOR_Y
      @vel_y = 0
      @angle = 90.0
      @score = 0
    end

    def jump!
      return unless ((FLOOR_Y - 10)..(FLOOR_Y + 10)).include?(@y)
      @angle = 45.0
    end

    def accelerate!
      @vel_y += Gosu::offset_y(@angle, 3.5)
    end

    def move!
      @score += 1
      @y += @vel_y

      @angle = 135 if @y <= WINDOW_HEIGHT - MAX_JUMP_HEIGHT

      if @y > FLOOR_Y
        @angle = 90
        @y = FLOOR_Y
      end

      @vel_y *= 0.95
    end

    def draw
      if @y < FLOOR_Y
        @jump_image.draw_rot(PLAYER_X_POSITION, @y - (@height / 2), 1, 0)
      else
        @normal_image.draw_rot(PLAYER_X_POSITION, @y - (@height / 2), 1, 0)
      end
    end
  end
end

RunIt.new.show