require 'rubygems'
require 'json'

state={}
state[:i] = 0

class SinatraApp
  require 'sinatra'
  
  def initialize state
    # sinatra = Sinatra::Application.new
    set :app_file, __FILE__
    set :reload, true
    disable :run

    get '/:action/:data' do

      output = "Howdy doody! #{state[:i]} #{params.to_json}"
      state[:i] = 0
      output
    end

    get '/lo' do
      "HelLOW World!"
    end

    Sinatra::Application.run!
  end
end


t = Thread.new do
  loop do
    puts "#{state[:i]}"
    sleep 1
    state[:i] += 1
  end
end

sa = SinatraApp.new state
