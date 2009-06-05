#!/usr/bin/ruby
require 'twitter_followers.rb'

twitter_id = ARGV[0]
twitter_id ||= 'joshuabaer'
# test_id = 'rsbrown'
# test_id = 'rsbrown'

tf = TwitterFollowers.new(twitter_id)


start_time = Time.now

puts
puts "================"
puts " TRUE FOLLOWERS "
puts "================"
puts 

tf.followers # load the followers

  puts "Untrue followers breakdown (screen name : reason) : "
  tf.untrue_followers.each do |untrue_follower|
    puts "#{untrue_follower[:follower]["screen_name"]} : #{untrue_follower[:reason]}"
  end
puts
puts
puts "True Followers results for '#{twitter_id}':"
puts
puts "Total   Followers: #{tf.followers.length}"
puts "True    Followers: #{tf.true_followers.length} (#{'%.1f' % (tf.true_followers.length.to_f/tf.followers.length.to_f*100)}%)"
puts "Untrue  Followers: #{tf.untrue_followers.length} (#{'%.1f' % (tf.untrue_followers.length.to_f/tf.followers.length.to_f*100)}%)"
puts

time = Time.now - start_time
mins = time.to_i/60
secs = time - (mins*60)
puts "Total time: #{mins} mins, #{secs} secs."