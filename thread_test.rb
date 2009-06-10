#!/usr/bin/ruby

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
  while Time.now.to_i < stop_time
  end
end

while thread.status
  puts "#{thread.object_id} '#{thread[:exception]}'"
  puts Thread.current.id
  sleep 1
end

puts "finished"