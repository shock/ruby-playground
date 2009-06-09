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

profile = TwitterProxy::get_profile(login)

logfile = File.open( login + ".log", "w" ) 
logfile.puts "Running..."

page = 1
total_friends = profile['friends_count']
friend_count = 0
friends_following = 0
friends_not_following = 0

friends = TwitterProxy::get_friends(login, password, login, page)

num_results = friends.length



while num_results > 0 do

  logfile.puts "Processing your friends, page #" + page.to_s + " (100 friends per page)"
  logfile.flush

  friends.each do |friend|
    friend_count += 1
    logfile.puts 'Checking ' + friend['name'] + ', ' + friend_count.to_s + ' of ' + total_friends.to_s
    friend_id = friend['id']
    logfile.flush
      
    their_page = 1
    followed = false

    their_followers = TwitterProxy::get_friends(login, password, friend_id, their_page )
    num_their_results = their_followers.length   

    while num_their_results > 0 && !followed do
      logfile.puts "Processing " + friend['name'] + "\'s friends, page #" + their_page.to_s + " (100 fpp)"
      logfile.flush
      their_followers.each do |their_friend|
        #puts their_friend['screen_name']
        if their_friend['screen_name'] == login
          followed = true
          break
        end
      end
      if followed then break end
      their_page += 1
      their_followers = TwitterProxy::get_friends(login, password, friend_id, their_page )
      num_their_results = their_followers.length   
    end
      
  
    if !followed
      logfile.puts friend['name'] + ' is not following ' + login
      logfile.flush
      
      ################################################
      ################################################
      logfile.puts 'Unfollowing ' + friend['name']
      logfile.flush
      resp = TwitterProxy::destroy_friend(login, password, friend_id)
      puts resp.to_s
      ################################################
      ################################################

      friends_not_following += 1
    else
      logfile.puts friend['name'] + ' is following ' + login
      logfile.flush
      friends_following += 1
    end
  end
  
  page += 1
  friends = TwitterProxy::get_friends(login, password, login, page)

  num_results = friends.length
  total_friends += num_results
end  

logfile.puts ""
logfile.puts "Total Friends: " + total_friends.to_s
logfile.puts "Friends Not Following: " + friends_not_following.to_s
logfile.puts "Friends Following: " + friends_following.to_s
logfile.flush
logfile.close