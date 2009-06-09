#!/usr/bin/ruby
#
# Script to auto-unfollow any friends of a twitter account who aren't following that account.
#
# TODO:  Log followed friends to a file.  Read that file on subsequent executions and do not
#        bother checking them again.  This would be useful if the script is interrupted for some
#        reason.


require 'twitter'
require 'highline/import'



def get_password( prompt='Password: ' )
  ask(prompt) { |q| q.echo = false }
end

def get_login( prompt='Login: ' )
  ask(prompt) { |q| }
end

login = get_login('Enter Twitter Id: ')
password = get_password

tp = TwitterProxy.new(login, password)

logfile = File.open( login + ".log", "a" ) 
logfile.puts "Running..."

friend_count = follower_count = 0

profile = tp.get_profile(login)
total_friends = profile['friends_count']
total_followers = profile['followers_count']


## Get friends

  friend_ids = tp.get_friend_ids(login)

## Get followers

  follower_ids = tp.get_follower_ids(login)


bad_friend_ids = friend_ids - follower_ids
good_friend_ids = friend_ids & follower_ids

puts ''
puts "SUMMARY"
puts "-------"
puts "Total Friends: " + friend_ids.length.to_s
puts "Friends Not Following: " + bad_friend_ids.length.to_s
puts "Friends Following: " + good_friend_ids.length.to_s
# Unfollow non-followers...

friends_removed = 0

puts 'Removing bad friends...'
bad_friend_ids.each do |friend_id|
  resp = tp.destroy_friend(friend_id)
  #resp = Hash.new
  #resp['name'] = friend_id.to_s
  if( resp['error'] == nil )
    friends_removed += 1
    logfile.puts( resp['name'] + ' deleted.')
    #puts( resp['name'] + ' deleted.')
  else
    friends_removed += 1
    logfile.puts( resp['name'] + ' delete failed.')
    #puts( resp['name'] + ' delete failed.')
   end
end

puts "Friends Removed: " + friends_removed.to_s
logfile.flush
logfile.close
