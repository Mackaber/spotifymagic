require 'json'
require 'faraday'
require 'env'

AUTH = ENV['ACCESS_TOKEN']

def add_queue(song) 
  conn = Faraday.new(url: "https://api.spotify.com")

  resp = conn.post do |req|
    req.url "/v1/me/player/add-to-queue?uri=#{song}&device_id=0f62b56d61809ab70140eeed4acea524573227e5"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.headers['Authorization'] = AUTH
  end
  # puts resp.body
  resp
end

def search(song) 
  conn = Faraday.new(url: "https://api.spotify.com")

  resp = conn.get do |req|
    req.url "/v1/search?q=#{song}&type=track&market=MX&limit=5"
    req.headers['Content-Type'] = 'application/json'
    req.headers['Accept'] = 'application/json'
    req.headers['Authorization'] = AUTH
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
  if req.path == "/add_song" && req['song'] # && req['magic_word'] == "housebreakers2135806Israelites"
    add_queue(req['song'])
    # puts resp.body
    response = "<html><script>window.close();</script></html>"
  elsif req.path == "/search_and_add" && req['q'] # && req['magic_word'] == "housebreakers2135806Israelites"
    track = search(req['q'])
    if track
      add_queue(track['uri'])
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