#!/usr/bin/ruby
f = File.open("testwrite.txt", "w")
f.flock File::LOCK_EX
retries = 15
while retries > 0
  puts retries.to_s + "Writing #{ARGV[0]}"
  f.write("#{ARGV[0]}\n")
  sleep 1
#  retries -= 1
end
f.flock File::LOCK_UN
f.close
