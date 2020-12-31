require_relative '../app/hangman'

game = Hangman.new(ARGV[0])
game.login
game.start_game

while game.active
  res = game.make_guess
  puts game.guesses
end

puts res['message']
puts res['correct_answer']
