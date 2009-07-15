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

user = get_login('Enter Twitter Id: ')
# password = get_password
login = 'buzzmanager_api'
password = 'buzzshock'

tp = TwitterProxy.new(login, password)

friend_count = follower_count = 0

profile = tp.get_profile(login)
total_friends = profile['friends_count']
total_followers = profile['followers_count']


## Get friends

## Get followers

  follower_ids = tp.get_follower_ids(user)
puts "Got #{follower_ids.length} followers for #{user}."
count = 0
follower_ids.each do |follower_id|
  puts "getting followers for #{follower_id}..."
  second_follower_ids = tp.get_follower_ids(follower_id.to_s)
  puts "#{second_follower_ids.length.to_s} followers."
  count += second_follower_ids.length
end

puts ''
puts ''
puts ''
puts ''
puts "RESULTS"
puts "-------"
puts "# of #{user}'s Followers: " + follower_ids.length.to_s
puts "# of their combined followers: " + count.to_s

