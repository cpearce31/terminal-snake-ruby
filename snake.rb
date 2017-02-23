require 'rubygems'
require 'bundler/setup'
require 'curses'

Curses.init_screen
Curses.stdscr.keypad(true) # enable arrow keys (required for pageup/down)
Curses.timeout = 150

class Snake
  def initialize(y, x)
    @head = [y, x]
    @tails = []
  end

  def move_to(y, x, expand)
    @tails.unshift(@head)
    unless expand
      @tails.pop
    end
    @head = [y, x]
  end

  def head_y
    @head[0]
  end

  def head_x
    @head[1]
  end

  def tails
    @tails
  end
end

class Board
  # Chars must be an array with characters in the order [head, tail, loot, blank]
  def initialize (size, chars)
    @head, @tail, @loot, @blank = chars
    @size = size
    @snake_died = false
    @game_data = []
    (1..size).each do
      row = []
      (1..size).each do
        row << @blank
      end
      @game_data << row
    end
    @snake = Snake.new(rand(size), rand(size))
    @game_data[@snake.head_y][@snake.head_x] = @head
    @loot_pos = get_blank_coords()
    redraw()
  end

  def display
    output = ''
    @game_data.each do |row|
      row_string = ''
      row.each do |point|
        row_string << point << ' '
      end
      output << row_string << "\n"
    end
    output
  end

  def active
    !@snake_died
  end

  def has_tail
    @snake.tails.length > 0
  end

  def get_blank_coords
    rand_y = rand(@size)
    rand_x = rand(@size)
    got = @game_data[rand_y][rand_x]
    if got != @blank
      take2 = get_blank_coords()
      return take2
    end
    [rand_y, rand_x]
  end

  def redraw
    new_board = []
    @game_data.each do |row|
      new_row = []
      row.each do |point|
        new_row.push(@blank)
      end
      new_board << new_row
    end

    new_board[@snake.head_y][@snake.head_x] = @head
    new_board[@loot_pos[0]][@loot_pos[1]] = @loot

    @snake.tails.each do |coords|
      tail_y, tail_x = coords
      new_board[tail_y][tail_x] = @tail
    end

    @game_data = new_board
  end

  def move_snake direction
    y = @snake.head_y
    x = @snake.head_x
    next_y = y
    next_x = x
    case direction
    when :up
      next_y -= 1
    when :right
      next_x += 1
    when :down
      next_y += 1
    when :left
      next_x -= 1
    end
    if @game_data[next_y] ==  nil ||
       @game_data[next_y][next_x] == nil ||
       @game_data[next_y][next_x] == @tail ||
       next_y < 0 ||
       next_x < 0
      @snake_died = true
    elsif @game_data[next_y][next_x] == @loot
      @snake.move_to(next_y, next_x, true)
      @loot_pos = get_blank_coords()
      redraw()
    else
      @snake.move_to(next_y, next_x, false)
      redraw()
    end
  end
end

board = Board.new(20, ['0', 'o', '$', '.'])

$current_direction = nil

loop do
  if !board.active()
    break
  end
  Curses.addstr(board.display)
  key = Curses.getch
  case key
  when Curses::KEY_LEFT
    unless board.has_tail() && $current_direction == :right
      $current_direction = :left
    end
  when Curses::KEY_RIGHT
    unless board.has_tail() && $current_direction == :left
      $current_direction = :right
    end
  when Curses::KEY_UP
    unless board.has_tail() && $current_direction == :down
      $current_direction = :up
    end
  when Curses::KEY_DOWN
    unless board.has_tail() && $current_direction == :up
      $current_direction = :down
    end
  end
    board.move_snake($current_direction)
    Curses.clear()
end
