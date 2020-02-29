require 'json'
require 'faraday'
require 'env'
require 'redis-rack'
require "base64"

CODE = ENV['CODE']
CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']

def refresh_token
  conn = Faraday.new(url: "https://accounts.spotify.com")

  credentials = "#{CLIENT_ID}:#{CLIENT_SECRET}"
  header = "Basic #{Base64.urlsafe_encode64(credentials, padding: true)}"

  resp = conn.post do |req|
    req.url "/api/token"
    req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    req.headers['Accept'] = 'application/json'
    req.headers['Authorization'] = header
    req.body = URI.encode_www_form({grant_type: "authorization_code", code: CODE, redirect_uri: "http://localhost:9292"})
  end
  resp.body

  #puts resp.body
  #"Bearer #{resp['access_token']}"
end

def add_queue(song,auth) 
  conn = Faraday.new(url: "https://api.spotify.com")

  resp = conn.post do |req|
    req.url "/v1/me/player/add-to-queue?uri=#{song}&device_id=0f62b56d61809ab70140eeed4acea524573227e5"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.headers['Authorization'] = auth
  end
  # puts resp.body
  resp
end

def search(song,auth) 
  conn = Faraday.new(url: "https://api.spotify.com")

  resp = conn.get do |req|
    req.url "/v1/search?q=#{song}&type=track&market=MX&limit=5"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.headers['Authorization'] = auth
  end
  puts resp.body
  results = JSON.parse resp.body
  if results["tracks"]["items"]
    results["tracks"]["items"][0]
  else
    nil
  end
end

app = Proc.new do |env|
  # puts AUTH
  req = Rack::Request.new(env)

  auth = refresh_token

  if req.path == "/add_song" && req['song'] # && req['magic_word'] == "housebreakers2135806Israelites"
    add_queue(req['song'],auth)
    # puts resp.body
    response = "<html><script>window.close();</script></html>"
  elsif req.path == "/search_and_add" && req['q'] # && req['magic_word'] == "housebreakers2135806Israelites"
    track = search(req['q'],auth)
    if track
      add_queue(track['uri'],auth)
      response = "Added: #{track['name']} from #{track['artists'][0]['name']} \n"
    else
      response = "Not found :(\n"
    end
  else
    response = "Usage... \n\nhttp://spotifymagic.mackaber.me/add_song?song=spotify:track:5KeyVNymqfqacvwLDseK8v\n\nOr\n\nhttp://spotifymagic.mackaber.me/search_and_add?q=Strangers%20Portishead"
  end

  [200, { 'Content-Type' => 'text/html; charset=UTF-8' }, [ response ]]
end

run app