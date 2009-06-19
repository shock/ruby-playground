#!/usr/bin/ruby

require 'net/https'

# make a method to check the process' memory usage
module Process
  def self.mem_used
    pid = Process.pid
    mem = `ps -o rsz #{pid}`
    mem.gsub!("RSZ", "").strip!
  end

  def self.show_mem_usage message
    puts "#{Process.mem_used}K #{message}"
  end
end


class ThreadTest
  # Shows handling of exceptions in a thread and storing
  # the exception in a thread variable.
  def exception_test

    thread = Thread.new do
      puts "first thread"
    end
    thread.join
    puts thread.object_id
    thread = Thread.new do
      begin
        raise RuntimeError.new( "Hello." )
      rescue 
        Thread.current[:exception] = $!
      end
      stop_time = Time.now.to_i + 3
      # sping the CPU!
      while Time.now.to_i < stop_time
      end
    end

    while thread.status
      puts "#{thread.object_id} '#{thread[:exception]}'"
      puts Thread.current.object_id
      sleep 1
    end

    puts "finished"
  end

  # stabilize the heap
  def mem_stable
    last_mem_used = 0
    i=0
    loop do
      mem_used = Process.mem_used
      break if mem_used == last_mem_used
      last_mem_used = mem_used
      puts "last_mem_used: #{last_mem_used}"
      i += 1
    end
    puts "Memory heap stable at #{last_mem_used}K.  It took #{i} iterations."
  end
  
  def initialize
  end

  def http_get
    http = Net::HTTP.new('twitter.com', 80)
    data = http.start do |http_inst|
      req = Net::HTTP::Get.new("/")
      # req.basic_auth "buzzmanager_api", "buzzshock"
      resp, data = http_inst.request(req)
      data
    end
  end

  # test the memory consumption of instantiating a thread
  def memory_test num_iterations, wait
    puts "Before: #{Process.mem_used}K"
    threads = []
    start_time = Time.now
    1.upto num_iterations do |i|
      thread = Thread.new do
         http_get
         $stdout.sync = true
         printf(".")
      end
      threads << thread
      thread.join if wait
    end
    threads.each do |thread|
      thread.join
    end
    puts "After: #{Process.mem_used}K"
    puts "Time: #{Time.now - start_time} secs"
  end
  
  def background_test
  end
end

tt = ThreadTest.new

tt.mem_stable
tt.memory_test 500, true
tt.memory_test 500, false
  