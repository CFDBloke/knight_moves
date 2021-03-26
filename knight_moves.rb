# frozen_string_literal: true

# An addon to the String class to change the colour of the text
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end
end

# The class for displaying the chessboard
class ChessBoard
  def initialize(initial_column, initial_row)
    @knight = Knight.new(initial_column, initial_row)
    @vertices = VertexList.new
    draw
  end

  def draw
    8.times do |row_number|
      print '---------'
      8.times { draw_row_top }
      print "+\n"
      draw_board_row(row_number)
    end
    print '---------'
    8.times { draw_row_top }
    print "+\n"
    draw_row_bottom
  end

  def find_path(target_column, target_row)
    @knight.moves_to(target_column, target_row, @vertices)
    draw
    output_path
  end

  private

  def draw_row_top
    print '+---------'
  end

  def draw_row_bottom
    4.times do |row|
      print '         |'
      8.times do |num|
        draw_number_row(num + 1, row + 1)
        print '|'
      end
      print "\n"
    end
  end

  def draw_board_row(row_number)
    4.times do |row|
      draw_number_row(row_number + 1, row + 1)
      8.times do |column|
        @knight.print_row(row_number, column, row)
      end
      print "|\n"
    end
  end

  def draw_number_row(number, row)
    number_hash = { 1 => { 1 => '         ', 2 => '    |    ', 3 => '    |    ', 4 => '         ' },
                    2 => { 1 => '   __    ', 2 => '   __|   ', 3 => '  |__    ', 4 => '         ' },
                    3 => { 1 => '   __    ', 2 => '   __|   ', 3 => '   __|   ', 4 => '         ' },
                    4 => { 1 => '         ', 2 => '  |__|   ', 3 => '     |   ', 4 => '         ' },
                    5 => { 1 => '   __    ', 2 => '  |__    ', 3 => '   __|   ', 4 => '         ' },
                    6 => { 1 => '   __    ', 2 => '  |__    ', 3 => '  |__|   ', 4 => '         ' },
                    7 => { 1 => '   __    ', 2 => '     |   ', 3 => '     |   ', 4 => '         ' },
                    8 => { 1 => '   __    ', 2 => '  |__|   ', 3 => '  |__|   ', 4 => '         ' } }
    print number_hash[number][row]
  end

  def output_path
    puts "The path from #{@knight.path_coords.first} to #{@knight.path_coords.last} requires a minimum of "\
    "#{@knight.path_coords.length - 1} moves. These are as follows:"
    @knight.path_coords.each { |position| p position }
  end
end

# Representation of a square on the chess board
class Square
  attr_accessor :row, :column, :position, :adjacents

  def initialize(column, row)
    @row = row
    @column = column
    @position = [column, row]
    @adjacents = find_adjacents(column, row)
  end

  private

  def find_adjacents(column, row)
    adjacents = initial_adjacents(column, row)
    adjacents.select { |position| position[0].between?(1, 8) && position[1].between?(1, 8) }
  end

  def initial_adjacents(column, row)
    [[column + 2, row + 1], [column + 2, row - 1], [column + 1, row + 2], [column + 1, row - 2],
     [column - 2, row + 1], [column - 2, row - 1], [column - 1, row + 2], [column - 1, row - 2]]
  end
end

# The list of squares on the chessboard
class VertexList
  attr_reader :vertex_array

  def initialize
    @vertex_array = []
    build_vertex_list
    @size = @vertex_array.length
    @vertex_array = index_adjacents
  end

  def build_vertex_list
    8.times do |column|
      8.times do |row|
        @vertex_array.push(Square.new(column + 1, row + 1))
      end
    end
  end

  def breadth_first_search(start_pos, end_pos)
    start_pos_index = @vertex_array.index { |square| square.position == start_pos }
    end_pos_index = @vertex_array.index { |square| square.position == end_pos }

    prev = solve(start_pos_index)

    reconstruct_path(start_pos_index, end_pos_index, prev)
  end

  private

  def solve(start)
    queue = []
    queue.push(start)

    visited = Array.new(@size, false)
    visited[start] = true

    manage_queue(queue, visited, Array.new(@size, nil))
  end

  def reconstruct_path(_start, end_, prev)
    path = []
    add_to_path(path, end_, prev)
    path.reverse
  end

  def manage_queue(queue, visited, prev)
    return prev if queue.empty?

    node = queue.shift
    neighbours = @vertex_array[node].adjacents
    neighbours.each do |neighbour|
      next if visited[neighbour]

      queue.push(neighbour)
      visited[neighbour] = true
      prev[neighbour] = node
    end
    manage_queue(queue, visited, prev)
  end

  def add_to_path(path, node, prev)
    return path if node.nil?

    path.push(node)
    add_to_path(path, prev[node], prev)
  end

  def index_adjacents
    @vertex_array.each do |square|
      square.adjacents = square.adjacents.map do |position|
        @vertex_array.index { |sq| sq.position == position }
      end
    end
  end
end

# The class to represent the knight piece
class Knight
  attr_accessor :row, :column, :path, :path_coords

  def initialize(column, row)
    @row = row
    @column = column
    @path = []
    @path_coords = [[@column, @row]]
  end

  def print_row(row_number, column, row)
    on_path = @path_coords.include?([column + 1, row_number + 1])
    if on_path
      print "|#{draw(row + 1, @path_coords.index([column + 1, row_number + 1]))}"
    else
      print '|         '
    end
  end

  def moves_to(target_column, target_row, vertices)
    @path = vertices.breadth_first_search([@column, @row], [target_column, target_row])

    @path_coords = @path.map { |index| vertices.vertex_array[index].position }
  end

  private

  def draw(row, path_number = 1)
    knight_hash = { 1 => "  __/\\  #{path_number}".colorize(42).colorize(1),
                    2 => ' /__  \  '.colorize(42).colorize(1),
                    3 => '   /  |  '.colorize(42).colorize(1),
                    4 => '  /____\ '.colorize(42).colorize(1) }
    knight_hash[row]
  end
end

def start
  start_pos = request('initial')

  board = ChessBoard.new(start_pos[0], start_pos[1])

  target_pos = request('target')
  in_range?(target_pos) ? board.find_path(target_pos[0], target_pos[1]) : restart
  finish
end

def finish
  puts "Would you like to find a path for a different set of start and end points? ('y' for yes, anything else for no)"
  answer = gets.chomp.downcase
  %w[y yes].include?(answer) ? start : (puts 'Ok, thanks for stopping by!!')
end

def in_range?(position)
  position[0].between?(1, 8) && position[1].between?(1, 8)
end

def request(position)
  puts "Please specify the #{position} position of your Knight as two comma separated integers, less than 8 "\
  "(e.g. '1,5'):"
  pos = gets.chomp.split(',')
  pos = pos.map(&:to_i)
  if in_range?(pos)
    pos
  else
    puts "The #{position} coordinates entered do not fall on the gameboard. Try again...\n"
    request(position)
  end
end

puts "\n"
puts 'Welcome to Knight Moves, please make sure that your terminal window is wide enough to fit the full chessboard'\
' width on.'
puts "The outputs will look weird if you don\'t!"
puts "\n"
start
