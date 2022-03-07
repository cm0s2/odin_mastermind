# frozen-string-literal: true

require 'pry-byebug'

# Mastermind class
class Mastermind
  attr_reader :feedback, :guesses

  MAX_ATTEMPTS = 12

  def initialize(player1_class, player2_class)
    puts "Type 1 to play as codemaker, 2 to play as code breaker"
    choice = gets.chomp.to_i

    if choice == 1
      @codemaker = player1_class.new(self)
      @codebreaker = player2_class.new(self)
    elsif choice == 2
      @codemaker = player2_class.new(self)
      @codebreaker = player1_class.new(self)
    end

    @guesses = []
    @feedback = []
  end

  def play
    until game_over?
      guess = @codebreaker.make_guess
      feedback = @codemaker.give_feedback(guess)
      # puts "Correct: #{result[:correct_position]}, wrong: #{result[:wrong_position]}"
      @guesses.push guess
      @feedback.push feedback
      print_board
    end
  end

  private

  def game_over?
    return false if @guesses.empty?
    return true if @guesses.count >= MAX_ATTEMPTS
    return true if @guesses.last == @codemaker.code

    false
  end

  def print_board
    puts "\n # |  Guess  | P C\n" \
         "------------------\n"
    @guesses.each_with_index do |guess, i|
      feedback = @codemaker.give_feedback(guess)
      guess_number = (i + 1).to_s.rjust(2, ' ')
      print "#{guess_number} | "
      guess.code.each do |slot|
        print "#{slot} "
      end
      puts "| #{feedback[:correct_position]} #{feedback[:wrong_position]}\n"
    end
  end
end

# Player class
class Player
  attr_reader :code

  # @score
  def initialize(game)
    @code = make_code
    @game = game
  end

  def make_guess
    print 'Make your guess: '
    Code.new(gets.split.map(&:to_i))
  end

  def make_code
    print 'Set your code: '
    Code.new(gets.split.map(&:to_i))
  end

  def give_feedback(guess)
    guess.feedback(code)
  end
end

# ComputerPlayer class
class ComputerPlayer < Player
  def initialize(game)
    super(game)
    @possible_codes = []
    @all_codes = []
  end

  def generate_possible_codes
    result = (1111..6666).to_a
    result.map! { |num| num.to_s.chars.map(&:to_i) }
    result.reject! { |code| (code & [7, 8, 9, 0]).any? }
    result.map! { |code| Code.new(code) }
    result
  end

  def make_code
    new_code = []
    4.times { new_code.push(rand(1..6)) }
    p new_code
    Code.new(new_code)
  end

  def make_guess
    # Create the set S of 1,296 possible codes (1111, 1112 ... 6665, 6666)
    @possible_codes = generate_possible_codes if @possible_codes.empty?
    @all_codes = @possible_codes.clone if @all_codes.empty?

    # Start with initial guess 1122
    return Code.new([1, 1, 2, 2]) if @game.guesses.length.zero?

    # Remove from S any code that would not give the same response if it (the guess) were the code.
    feedback = @game.feedback.last
    current_guess = @game.guesses.last
    @possible_codes.filter! { |code| code.feedback(current_guess) == feedback }

    # Find most optimal guess
    minimax(@all_codes, @possible_codes)
  end

  def minimax(all_guesses, possible_guesses)
    return possible_guesses.first if possible_guesses.length == 1

    tmax = 0
    highestt = possible_guesses.first

    all_guesses.each_with_index do |tguess, index|
      smin = possible_guesses.length
      lowests = possible_guesses.first

      possible_guesses.each do |sguess|
        feedback = sguess.feedback(tguess)
        deleted = possible_guesses.count { |curr_guess| curr_guess.feedback(tguess) != feedback }
        if deleted <= smin
          smin = deleted
          lowests = sguess
        end
      end
      puts "Max: #{tmax}, index: #{index}, possible_guesses: #{possible_guesses.length}"
      if smin > tmax
        tmax = smin
        highestt = lowests
      end
    end
    highestt
  end
end

# Guess class
class Code
  attr_reader :code

  def initialize(code)
    @code = code
  end

  def feedback(guess)
    wrong_guess_pegs = []
    wrong_answer_pegs = []
    result = { correct_position: 0, wrong_position: 0 }

    @code.zip(guess.code).each do |answer_peg, guess_peg|
      if guess_peg == answer_peg
        result[:correct_position] += 1
      else
        wrong_guess_pegs.push(guess_peg)
        wrong_answer_pegs.push(answer_peg)
      end
    end

    wrong_guess_pegs.each do |peg|
      if wrong_answer_pegs.include?(peg)
        wrong_answer_pegs.delete(peg)
        result[:wrong_position] += 1
      end
    end

    result
  end

  def ==(other)
    @code == other.code
  end
end

# Mastermind.new(ComputerPlayer, Player).play
Mastermind.new(ComputerPlayer, Player).play

# code = Code.new([6, 2, 2, 1])
# guess = Code.new([1, 1, 2, 2])
# code.feedback(guess)

# Wrong: Code: [6, 5, 3, 2], Guess: [6, 6, 6, 6], Feedback: {:correct_position=>1, :wrong_position=>3}
# Correct: Code: [6, 5, 3, 2], Guess: [6, 6, 6, 6], Feedback: {:correct_position=>1, :wrong_position=>0}
