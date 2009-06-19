#!/usr/bin/ruby
#
# Script to auto-unfollow any friends of a twitter account who aren't following that account.
#
# TODO:  Log followed friends to a file.  Read that file on subsequent executions and do not
#        bother checking them again.  This would be useful if the script is interrupted for some
#        reason.


require 'twitter'
require 'rubygems'
require 'highline/import'



def get_password( prompt='Password: ' )
  ask(prompt) { |q| q.echo = false }
end

def get_login( prompt='Login: ' )
  ask(prompt) { |q| }
end

def get_answer( prompt )
  ask(prompt) { |q| q.echo = true}
end

login = get_login('Enter Twitter Id: ')
password = get_password
answer = get_answer("Are you sure you want to block ALL followers for #{login}? (y/N) : ")


if answer.downcase == "y"
  tp = TwitterProxy.new(login, password)

  friend_count = follower_count = 0

  profile = tp.get_profile(login)
  total_followers = profile['followers_count']


  ## Get followers

  follower_ids = tp.get_follower_ids(login)


  puts 
  puts "SUMMARY"
  puts "-------"
  puts "Total Followers: " + follower_ids.length.to_s
  puts
  logfilename = login + ".log"
  logfile = File.open( logfilename, "a" ) 

  # Unfollow non-followers...

  followers_removed = 0

  logfile.puts "Running..."
  puts 'Removing followers...'
  follower_ids.each do |follower_id|
    resp = tp.block(follower_id)
    #resp = Hash.new
    #resp['name'] = friend_id.to_s
    if( resp['error'] == nil )
      followers_removed += 1
      logfile.puts( resp['name'] + ' deleted.')
      #puts( resp['name'] + ' deleted.')
    else
      logfile.puts( resp['name'] + ' delete failed.')
      #puts( resp['name'] + ' delete failed.')
     end
  end


  puts "Followers Blocked: #{followers_removed.to_s} of #{follower_ids.length}."
  puts "Re-run if necessary to block any remaining followers."
  puts
  puts "Results logged to #{logfilename}."
  puts
  logfile.flush
  logfile.close

else
  puts
  puts "No action taken."
  puts
end

