require 'oauth2'

class SpotifyClient < OAuth2::Client
    attr_accessor :token

    @@device_id = "0f62b56d61809ab70140eeed4acea524573227e5"

    def initialize(client_id, client_secret, redirect_uri)
        super(client_id, client_secret, :site => "https://api.spotify.com/")
        @redirect_uri = redirect_uri # "http://localhost:9292"
        options[:authorize_url] = "https://accounts.spotify.com/authorize"
        options[:token_url] = "https://accounts.spotify.com/api/token"
    end

    def get_authorize_url
        auth_code.authorize_url(
            redirect_uri: @redirect_uri, 
            scope: "user-modify-playback-state,user-read-private,user-read-email"
        )
    end

    def get_auth_token(code)
        @token = auth_code.get_token(
            code, 
            redirect_uri: @redirect_uri, 
            params: {grant_type: "authorization_code"}
        )
    end

    def add_queue(song)
        response = @token.post("/v1/me/player/add-to-queue", 
            params: {
                uri:  song,
                device_id: @@device_id
        })
        # Maybe check if the response was sucessful?
    end

    def search(song)
        response = @token.get("/v1/search", 
            params: {
                q: song, 
                type: "track", 
                limit: 5, 
                market: "MX"
        })
        puts response.body
        JSON.parse response.body
    end

    def play_now(song)
        add_queue(song)
        @token.post("/v1/me/player/next",
            params: { device_id: @@device_id }
        )
        # Maybe check if the response was sucessful?
    end

end