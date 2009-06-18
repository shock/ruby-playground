#!/usr/bin/ruby

require 'rubygems'
require 'net/https'
require 'json'
require 'concurrency'
require 'pp'

def http_get id, page, type='json'
  http = Net::HTTP.new('twitter.com', 80)
  data = http.start do |http_inst|
    path = "/statuses/followers/#{id}.#{type}?page=#{page}"
    req = Net::HTTP::Get.new(path)
    req.basic_auth "buzzmanager_api", "buzzshock"
    puts "getting #{path}"
    resp, data = http_inst.request(req)
    puts "done"
    data
  end
  results = JSON.parse(data)
  # pp results
  results.sort {|a,b| a["screen_name"] <=> b["screen_name"]}
end

def collect1 pages
  id = 'joshuabaer'
  results = []
  1.upto pages do |page|
    results += http_get id, page
  end
  results
end

def collect2 pages
  id = 'joshuabaer'
  results = []
  jobs = []
  1.upto pages do |page|
    bj = BackgroundJob.new do 
      http_get id, page
    end
    jobs << bj
  end
  jobs.each do |bj|
    results += bj.result
  end
  results
end  

def time_it( &block )
  start_time = Time.now
  result = block.call
  puts "Time: #{Time.now - start_time} secs"
  result
end

def write_it( filename, contents )
  file = File.open(filename, "w")
  file.write( contents )
  file.close
end

def test
  pages = 10
  results1 = time_it {collect1 pages}
  write_it( "results1", results1.to_yaml )
  puts
  results2 = time_it {collect2 pages}
  write_it( "results2", results2.to_yaml )
  puts
  puts "results1 == results2 => #{results1 == results2}"
end

test

