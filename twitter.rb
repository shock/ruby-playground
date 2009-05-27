require 'uri'
require 'rubygems'
require 'grackle'

class Twitter
  @@login="bdoughty"
  @@password="yamaha"
  @@grackle = Grackle::Client.new(:username=>@@login,:password=>@@password)

  def self.get_num_followers_for_user user_name
    ustats = @@grackle.users.show.json?( :screen_name=>user_name )
    ustats.friends_count
  end

  def self.test_search terms
    results = @@grackle[:search].search? :q=>terms
  end

  def self.test
    threads = []
    start_time = Time.now
    0.upto 5 do |i|
      threads << Thread.new(i) { |j|
        successful = false
        while !successful
          begin
#            puts j.to_s + " - " + (self.get_num_followers_for_user( "bdoughty" )).to_s
            puts j.to_s + " - " + (self.test_search( "bdoughty" )).to_s
            successful = true
          rescue
            puts j.to_s + " - " + "Exception #{$!} - retrying..."
          end
        end
      }
    end
    threads.each { |aThread|
      puts aThread
      aThread.join
    }
    puts Time.now - start_time
  end
end

Twitter.test
