require 'twitter'
require 'pp'

class Object
  def blank?
    if self.class == NilClass
      return true
    elsif self.class == String
      if self == ""
        return true
      else
        return false
      end
    else
      return false
    end
  end
end

class TwitterFollowers
  
  TRUE_FOLLOWER_MAX_FOLLOWERS=10000
  TRUE_FOLLOWER_MIN_FOLLOWERS=1
  TRUE_FOLLOWER_MAX_FRIENDS=1000

  def get_followers
    @followers = @tp.get_followers(@twitter_id)
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
      elsif( follower["followers_count"] > TRUE_FOLLOWER_MAX_FOLLOWERS )
        untrue_follower[:reason] = "Has more than #{TRUE_FOLLOWER_MAX_FOLLOWERS} followers."
        @untrue_followers << untrue_follower
      elsif( follower["followers_count"] < TRUE_FOLLOWER_MIN_FOLLOWERS )
        untrue_follower[:reason] = "Has less than #{TRUE_FOLLOWER_MIN_FOLLOWERS} followers."
        @untrue_followers << untrue_follower
      elsif( follower["followers_count"] > TRUE_FOLLOWER_MAX_FRIENDS )
        untrue_follower[:reason] = "Follows more than #{TRUE_FOLLOWER_MAX_FRIENDS} others."
        @untrue_followers << untrue_follower
      elsif( follower["profile_image_url"] == "http://static.twitter.com/images/default_profile_normal.png" )
        untrue_follower[:reason] = "Has default profile image."
        @untrue_followers << untrue_follower
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
