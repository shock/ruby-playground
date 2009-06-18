pid = Process.pid
puts "pid: #{pid}"
mem = `ps -o rsz #{pid}`
mem.gsub!("RSZ", "").strip!
puts "mem: #{mem}"
