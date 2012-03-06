require 'cora'
require 'siri_objects'

require 'open-uri'
require 'json'
require 'uri'

#######
# Control Spotify with your voice.
# Simply say "Spotify, play me some Nirvana"
######

class SiriProxy::Plugin::Spotify < SiriProxy::Plugin

  SPOTIFY_CHECK = '(spotify|spotter five|spot of phi|spot fie|spot a fight|specify|spot if i|spotted by|stultify)'
  PLAY_CHECK = '(play|plate|place)'

  def initialize(config)
    #if you have custom configuration options, process them here!
  end
  
  # I do think order is important as patterns partly match the same
  
  listen_for /#{SPOTIFY_CHECK} play (the)? (last|previous) (track|song)/i do
    # Sending this command once only goes to the beginning of the current track. So let's send it twice!
    commandSpotify("previous track")
    response = commandSpotify("previous track\n#{detailedNowPlayingCommand()}")
    say "Ok, playing #{response}"
    
    request_completed
  end
  
  listen_for /#{SPOTIFY_CHECK} play (the)? next (track|song)?/i do
    response = commandSpotify("next track\n#{detailedNowPlayingCommand()}")
    say "Ok, playing #{response}"
    
    request_completed
  end
  
  listen_for /#{SPOTIFY_CHECK} what (band|singer|artist|track|group|song) is this/i do
    response = commandSpotify("#{detailedNowPlayingCommand()}")
    say "Playing #{response}"
    
    request_completed
  end
  
  listen_for /#{SPOTIFY_CHECK} #{PLAY_CHECK} (.*) (?:by|with) (.*)/i do |keyword, song, artist|
    
    cleansong = URI.escape(song.strip)
    cleanartist = URI.escape(artist.strip)
	  
    results = searchSpotify("artist:#{cleanartist}+track:#{cleansong}")
    
    if (results["tracks"].length > 1)
      track = results["tracks"][0]

      say "Playing #{track["name"]} by #{track["artists"][0]["name"]}"
      `open #{track["href"]}`
    else
      say "I could not find #{song} by #{artist}"
    end
    
    request_completed
  end

  listen_for /#{SPOTIFY_CHECK} #{PLAY_CHECK} artist (.*)/i do |keyword, query|
    
    artist = URI.escape(query.strip)
	  
	  results = searchSpotify("#{artist}")
    
    if (results["tracks"].length > 1)
      track = results["tracks"][0]

      say "Playing #{track["name"]} by #{track["artists"][0]["name"]}"
      `open #{track["href"]}`
    else
      say "I could not find anything by #{query}"
    end
    
    request_completed
  end
  
  listen_for /#{SPOTIFY_CHECK} p(a|u|o).+/i do
    
    commandSpotify("pause")
    say "Pausing Spotify..."
    
    request_completed
  end
  
  def detailedNowPlayingCommand()
		return "set nowPlaying to current track\nreturn \"\" & name of nowPlaying & \" by \" & artist of nowPlaying"
	end
  
  def commandSpotify(command)
    return (`osascript -e 'tell application "Spotify"\n#{command}\nend'`).strip
  end

  def searchSpotify(query, type="track")
    return JSON.parse(open("http://ws.spotify.com/search/1/#{type}.json?q=#{query}").read)
  end
end
