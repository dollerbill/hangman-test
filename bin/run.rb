require_relative '../app/hangman'

game = Hangman.new(ARGV[0])
game.login
game.start_game
game.trim_dictionary(game.length)

while game.active
  res = game.make_guess
  puts "#{game.guesses}: #{res['guesses']}"
end

puts res['message']
puts res['correct_answer']
