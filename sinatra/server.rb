require 'rubygems'
require 'sinatra'
require 'json'

state={}
state[:i] = 0

def sinatra_init state
  get '/:action/:data' do
  
    output = "#{state[:i]} #{params.to_json}"
    state[:i] = 0
    output
  end

  get '/lo' do
    "HelLOW World!"
  end
end

t = Thread.new do
  loop do
    puts "#{state[:i]}"
    sleep 1
    state[:i] += 1
  end
end

sinatra_init state