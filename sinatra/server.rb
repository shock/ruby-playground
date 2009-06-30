require 'rubygems'
require 'sinatra'
require 'json'
i=0

get '/hi' do
  
  output = "Hello World ##{i}!\n#{params.to_json}"
  i = 0
  output
end


get '/lo' do
  "HelLOW World!"
end

t = Thread.new do
  loop do
    puts "#{i}"
    sleep 1
    i += 1
  end
end