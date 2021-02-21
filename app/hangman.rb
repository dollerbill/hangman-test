require 'http'
require 'pry'

class Hangman
  BASE_URL = 'https://prime-trust-hangperson-prod.herokuapp.com'.freeze
  VOWELS = %w[e a i o u].freeze
  CONSONANTS = %w[r t n s l c d p m h g b f y w k v x z j q].freeze

  attr_accessor :active, :correct, :email, :excluded, :game_id, :guesses, :length, :letters, :token, :words

  def initialize(email)
    @active = true
    @correct = []
    @email = email
    @guesses = 0
    @letters = ['r']
    @excluded = []
    @words = File.read(File.join(Dir.pwd, '../app', 'dictionary.txt')).split
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
    @length = res['length']
  end

  def trim_dictionary(length)
    @words = words.select { |w| w.length == length }
  end

  def make_guess
    letter = pick_letter(random_letter)
    url = "#{BASE_URL}/games/#{game_id}/guesses?token=#{token}&letter=#{letter}"
    response = HTTP.send(:post, url)
    res = JSON.parse(response)
    check_errors(response, res)
    select_concurrent_words(res)
    update_words(res, letter)
    update_game(res)
    remove_unnecessary_words
    res
  end

  private

  def check_errors(response, json)
    raise StandardError, "#{response.status}: #{json}" if response.status != 200

    true
  end

  def find_concurrent(response)
    # don't need concurrent if matching index
    response['progress']&.split('_')&.select { |p| p.length > 1 }
  end

  def pick_letter(letter)
    return letter if words.any? { |w| w.include?(letter) }

    @excluded << letter
    pick_letter(random_letter)
  end

  def random_letter
    ([VOWELS, CONSONANTS].sample - letters - excluded).first || (CONSONANTS - letters - excluded).first
  end

  def remove_unnecessary_words
    return unless @correct.any?

    @words = words.select do |w|
      @correct.all? { |l| w.include?(l) }
    end
  end

  def select_concurrent_words(response)
    concurrent = find_concurrent(response)
    return unless concurrent&.any?

    concurrent.each do |c|
      @words = words.select { |w| w.match?(c) }
    end
  end

  def update_game(response)
    @letters = response['guesses']
    @guesses += 1
    @active = false if response['message']
  end

  def update_words(response, letter)
    if response['correct']
      @correct << letter
    else
      @words = words.reject { |w| w.include?(letter) } #unless response['correct']
    end
  end
end
