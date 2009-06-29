#!/usr/bin/ruby
#
# Script to auto-unfollow all friends of a twitter account.
#


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
answer = get_answer("Are you sure you want to unfollow ALL friends for #{login}? (y/N) : ")


if answer.downcase == "y"
  tp = TwitterProxy.new(login, password)

  friend_count = friend_count = 0

  profile = tp.get_profile(login)
  total_friends = profile['friends_count']


  ## Get friends

  friend_ids = tp.get_friend_ids(login)


  puts 
  puts "SUMMARY"
  puts "-------"
  puts "Total Friends: " + friend_ids.length.to_s
  puts
  logfilename = login + ".log"
  logfile = File.open( logfilename, "a" ) 

  # Unfollow non-friends...

  friends_removed = 0

  logfile.puts "Running..."
  puts 'Removing friends...'
  $stdout.sync = true
  friend_ids.each do |friend_id|
    resp = tp.destroy_friend(friend_id)
    if( resp['error'] == nil )
      friends_removed += 1
      logfile.puts( resp['name'] + ' deleted.')
      printf(".")
    else
      logfile.puts( resp['name'] + ' delete failed.')
      puts( "\n#{resp['name']} - delete failed.")
     end
  end
  puts
  puts
  puts "Friends Deleted: #{friends_removed.to_s} of #{friend_ids.length}."
  puts "Re-run if necessary to block any remaining friends."
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

