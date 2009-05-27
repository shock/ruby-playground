#!/usr/bin/ruby

main_loop = true

while main_loop
  sleep 10
end

trap("INT") {main_loop = false}