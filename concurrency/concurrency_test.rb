#!/usr/bin/ruby

require 'rubygems'
require 'net/https'
require 'json'
require 'concurrency'
require 'pp'
@@page = 0

def http_get id, page, type='json'
  http = Net::HTTP.new('twitter.com', 80)
  data = http.start do |http_inst|
    path = "/statuses/followers/#{id}.#{type}?page=#{page}"
    req = Net::HTTP::Get.new(path)
    req.basic_auth "buzzmanager_api", "buzzshock"
    puts "getting #{path}"
    resp, data = http_inst.request(req)
    @@page += 1
    puts "* DONE - #{@@page}"
    data
  end
  results = JSON.parse(data)
  # pp results
  results.sort {|a,b| a["screen_name"] <=> b["screen_name"]}
end

# collect the old-fashioned serial way
def collect1 pages
  id = 'joshuabaer'
  results = []
  1.upto pages do |page|
    results += http_get id, page
  end
  results
end

# collect with concurrency using the BackgroundTasks directory
def collect2 pages
  id = 'joshuabaer'
  results = []
  tasks = []
  1.upto pages do |page|
    puts "queueing page #{page}"
    task = BackgroundTask.new do 
      http_get id, page
    end
    tasks << task
    task.run
  end
  tasks.each do |task|
    puts "task retrieved"
    results += task.result
  end
  results
end  

# collect with concurrency using the TaskCollection
def collect3 pages
  id = 'barackobama'
  results = []
  tasks = TaskCollection.new( 50 )
  1.upto pages do |page|
    puts "queueing page #{page}"
    task = BackgroundTask.new do 
      http_get id, page
    end
    tasks << task
  end
  i=0
  loop do
    i+=1
    puts "getting next task..."
    task = tasks.next_finished
    if !task
      puts "no more tasks"
      break
    else
      puts "task retrieved #{i}"
      results += task.result
    end
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
  pages = 15
  results1 = time_it {collect1 pages}
  results2 = time_it {collect2 pages}
  # verify it
  puts "results1 == results2 => #{results1 == results2}"
end


# test
collect3 100

