require 'redis'
require 'sinatra'
require 'dotenv/load'
require './spotify_client.rb'

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
REDIRECT_URL = ENV['REDIRECT_URL']

$redis = Redis.new(url: ENV["REDIS_URL"])
client = SpotifyClient.new(CLIENT_ID,CLIENT_SECRET,REDIRECT_URL)

if $redis.exists("mackaber:token_hash")
    token = $redis.get("mackaber:token_hash")
    client.token = OAuth2::AccessToken.from_hash(client,JSON.parse(token))
end

def check_token
    if client.token.expired?
        client.token.refresh!
    end
    yield
end

get '/' do
    client.get_authorize_url
end

get '/callback' do
    if client.get_auth_token(params[:code])
        $redis.set("mackaber:token_hash", client.token.to_hash.to_json)
        "SUCCESSFUL!"
    else
        "FAILED!"
    end
end

get '/add_song' do
    check_token do 
        client.add_queue(params[:song])
        "<html><script>window.close();</script></html>"
    end
end

get '/search_and_add' do
    check_token do 
        result = client.search(params['q'])
        track = result["tracks"]["items"][0]
        client.add_queue(track['uri'])
        
        "Added: #{track['name']} from #{track['artists'][0]['name']} \n"
    end
end