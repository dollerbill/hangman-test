require 'http'

class Hangman
  BASE_URL = 'https://prime-trust-hangperson-prod.herokuapp.com'.freeze
  VOWELS = %w[e a i o u].freeze
  CONSONANTS = %w[r t n s l c d p m h g b f y w k v x z j q].freeze

  attr_accessor :active, :email, :game_id, :guesses, :letters, :token, :words

  def initialize(email)
    @active = true
    @email = email
    @guesses = 0
    @letters = []
    @words = JSON.parse(File.read('app/dictionary.json'))
  end

  def login
    url = "#{BASE_URL}/players?email=#{email}"
    response = HTTP.send(:post, url)
    res = JSON.parse(response)
    check_errors(response, res)

    @token = res['token']
  end

  def start_game
    url = "#{BASE_URL}/games?token=#{token}"
    response = HTTP.send(:post, url)
    res = JSON.parse(response)
    check_errors(response, res)

    @game_id = res['game']
  end

  def make_guess
    letter = pick_letter(pick_random)
    url = "#{BASE_URL}/games/#{game_id}/guesses?token=#{token}&letter=#{letter}"
    response = HTTP.send(:post, url)
    res = JSON.parse(response)

    check_errors(response, res)

    update_words(res, letter)
    update_game(res)
    res
  end

  private

  def check_errors(response, json)
    raise StandardError, "#{response.status}: #{json}" if response.status != 200

    true
  end

  def pick_letter(letter)
    return letter if words.include?(letter)

    VOWELS - [letter] && CONSONANTS - [letter]
    pick_letter(pick_random)
  end

  def pick_random
    ([VOWELS, CONSONANTS].sample - letters || VOWELS - letters || CONSONANTS - letters).first
  end

  def update_game(response)
    @letters = response['guesses']
    @guesses += 1
    @active = false if response['message']
  end

  def update_words(response, letter)
    concurrent = response['progress']&.split('_')&.select { |p| p.length > 1 }

    @words.tap do |w|
      w.reject { |wr| wr.include?(letter) } unless response['correct']
      concurrent&.each { |c| w.select { |wr| wr.match?(c) } }
    end
  end
end
