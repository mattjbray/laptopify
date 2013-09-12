#!/usr/bin/env ruby

require 'json'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'spotify-dbus'

set :bind, '0.0.0.0'

class Spotify
  def self.get_metadata
    # TODO: only return metadata here, and use status
    # However calling both simultaneously makes it hang
    meta = SpotifyDBus::player['Metadata']
    meta['status'] = SpotifyDBus::player['PlaybackStatus']
    meta
  end

  def self.play_pause
    SpotifyDBus::player.PlayPause
  end

  def self.previous
    SpotifyDBus::player.Previous
  end

  def self.next
    SpotifyDBus::player.Next
  end

  def self.open_uri uri
    SpotifyDBus::player.OpenUri uri
  end

  def self.get_volume
    raw_volume = %x( pactl list sinks | grep -m 1 Volume )
    volume = /(\d{1,3})%/.match(raw_volume)[1]
  end

  def self.set_volume volume
    if volume.between?(0, 100)
      %x( pactl set-sink-volume @DEFAULT_SINK@ -- #{volume}% )
    end
  end

  def self.status
    SpotifyDBus::player['PlaybackStatus']
  end
end

get '/' do
  erb :index
end

get '/metadata' do
  JSON.generate(Spotify.get_metadata)
end

post '/play_pause' do
  Spotify.play_pause
end

post '/previous' do
  Spotify.previous
end

post '/next' do
  Spotify.next
end

post '/open_uri' do
  uri = JSON.parse(request.body.read)['uri']
  Spotify.open_uri uri
end

get '/volume' do
  Spotify.get_volume
end

post '/volume' do
  volume = JSON.parse(request.body.read)['volume'].to_i
  Spotify.set_volume volume
end

get '/status' do
  Spotify.status
end
