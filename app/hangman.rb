require 'http'

class Hangman
  ALPHABET = %w[e a r i o t n s l c u d p m h g b f y w k v x z j q].freeze
  BASE_URL = 'https://prime-trust-hangperson-prod.herokuapp.com'.freeze

  attr_accessor :active, :email, :game_id, :guesses, :letters, :token

  def initialize(email)
    @active = true
    @email = email
    @guesses = 0
    @letters = []
  end

  def login
    url = "#{BASE_URL}/players?email=#{email}"
    res = HTTP.send(:post, url)
    raise StandardError, "#{res.status}: #{JSON.parse(res)}" if error?(res)

    @token = JSON.parse(res)['token']
  end

  def start_game
    url = "#{BASE_URL}/games?token=#{token}"
    res = HTTP.send(:post, url)
    raise StandardError, "#{res.status}: #{JSON.parse(res)}" if error?(res)

    @game_id = JSON.parse(res)['game']
  end

  def make_guess
    letter = (ALPHABET - letters).first
    url = "#{BASE_URL}/games/#{game_id}/guesses?token=#{token}&letter=#{letter}"
    res = HTTP.send(:post, url)

    raise StandardError, "#{res.status}: #{JSON.parse(res)}" if error?(res)

    @letters = JSON.parse(res)['guesses']
    @guesses += 1
    @active = false if JSON.parse(res)['message']
    JSON.parse(res)
  end

  def error?(response)
    response.status != 200
  end
end
