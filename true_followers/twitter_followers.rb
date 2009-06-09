require 'twitter'
require 'pp'
require 'rubygems'
require 'typhoeus'
require 'base64'

class Object
  def blank? *args
    if self.class == NilClass
      return true
    elsif self.class == String
      if self == ""
        return true
      else
        return false
      end
    else
      self.method_missing args
    end
  end
end

class TwitterFollowers
  
  TRUE_FOLLOWER_MIN_FOLLOWERS=1
  TRUE_FOLLOWER_MAX_FRIENDS=1000
  TRUE_FOLLOWER_MIN_FRIENDS=2
  
  include Typhoeus
    remote_defaults :on_success => lambda {|response| JSON.parse(response.body)},
                    :on_failure => lambda {|response| puts "error code: #{response.code}"},
                    # :base_uri   => "http://twitter.com"
                    :base_uri   => "http://twitter.com"

    # define_remote_method :get_followers, {:path => '/statuses/followers/:id.json', :authorization => "Basic {Base64.b64encode("buzzmanager_api:buzzshock")}"}
    define_remote_method :get_followers, {:path => '/test.php', :authorization => "Basic #{Base64.b64encode("buzzmanager_api:buzzshock")}"}
  
  def get_profile
    @profile ||= @tp.get_profile(@twitter_id)
    @followers_count = @profile["followers_count"]
  end

  def get_followers
    @followers = @tp.get_followers(@twitter_id)
  end
  
  def typhoeus_get_followers
    get_profile
    fpp = 100 # followers per page
    max_pages = 100   # the max number of pages we are willing to fetch to get a reasonable sample of the followers
    total_theoretical_pages = (@followers_count + fpp - 1) / fpp  # how many pages we'd have to fetch to get all the followers
    if( total_theoretical_pages > max_pages )
      num_to_increment_per_retrieval = @followers_count / max_pages  # how many 
      num_pages = max_pages
    else # we're going to get all the pages
      num_to_increment_per_retrieval = fpp
      num_pages = total_theoretical_pages
    end
    @start_index = 0
    page_results = []
    1.upto( num_pages ) do 
      @page_number = @start_index / fpp + 1 # twitter starts with page 1, not page 0
      page_results << TwitterFollowers.get_followers(:id=>@twitter_id, :params=>{:page=>@page_number})
      @start_index += num_to_increment_per_retrieval
    end
    page_results
  end
  
  def analyze_followers
    @followers ||= get_followers
    @true_followers = []
    @untrue_followers = []
    @followers.each do |follower|
      untrue_follower = {}
      untrue_follower[:follower] = follower
      if( follower["following"] == true ) 
        @true_followers << follower
      elsif( follower["statuses_count"] <= 0 ) 
        untrue_follower[:reason] = "Never sent a tweet."
        @untrue_followers << untrue_follower
      elsif( follower["name"].blank? )
        untrue_follower[:reason] = "Name field is blank."
        @untrue_followers << untrue_follower
      elsif( follower["followers_count"] < TRUE_FOLLOWER_MIN_FOLLOWERS )
        untrue_follower[:reason] = "Has less than #{TRUE_FOLLOWER_MIN_FOLLOWERS} followers."
        @untrue_followers << untrue_follower
      elsif( follower["friends_count"] > TRUE_FOLLOWER_MAX_FRIENDS )
        untrue_follower[:reason] = "Follows more than #{TRUE_FOLLOWER_MAX_FRIENDS} others."
        @untrue_followers << untrue_follower
      elsif( follower["friends_count"] < TRUE_FOLLOWER_MIN_FRIENDS )
        untrue_follower[:reason] = "Follows more than #{TRUE_FOLLOWER_MIN_FRIENDS} others."
        @untrue_followers << untrue_follower
      #elsif( follower["profile_image_url"] == "http://static.twitter.com/images/default_profile_normal.png" )
      #  untrue_follower[:reason] = "Has default profile image."
      #  @untrue_followers << untrue_follower
      else
        @true_followers << follower
      end
    end
  end
  
  def true_followers
    analyze_followers if !@true_followers
    @true_followers
  end
  
  def followers
    @followers ||= get_followers
  end
  
  def untrue_followers
    analyze_followers if !@untrue_followers
    @untrue_followers
  end
  
  def initialize twitter_id
    @login = 'buzzmanager_api'
    @password = 'buzzshock'
    @twitter_id = twitter_id

    @tp = TwitterProxy.new(@login, @password)
    @followers = nil
  end
  
end
