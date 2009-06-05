#!/usr/bin/ruby
#
# Author:: William Doughty
# Documentation:: William Doughty
#
# Performs basic Twitter functions through the Twitter API.
#
require 'rubygems'
require 'json'
require 'uri'
require 'net/https'


# 
# The Twitter module contains functions to access to the Twitter API.
#
class TwitterAPI

  #
  # Returns a user's timeline.
  # +login+ - id of twitter to use for authentication
  # +password+ - password for authenticating user
  # +id+ - id of twitter user to retrieve timeline for (if not +login+)
  # +type+ - type of encoding, 'xml' is default, can also be 'json', or 'rss'
  #
  def get_user_timeline( id=nil, login=@login, password=@password, type='xml', count=nil )
    
    http = Net::HTTP.new('twitter.com', 80)
    data = http.start do |http_inst|
      path = "/statuses/user_timeline.#{type}"
      if id == nil then id = login end
      path += "?id=#{id}"
      if count != nil 
        path += "&count=#{count}"
      end
      req = Net::HTTP::Get.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
  end
 
  #
  # Returns a user's timeline as an array of hashes.
  # +login+ - id of twitter to use for authentication
  # +password+ - password for authenticating user
  # +id+ - id of twitter user to retrieve timeline for (if not +login+)
  # +count+ - number of tweets to return
  #
  def get_user_timeline_as_hash( id=nil, login=@login, password=@password )
    json_data = get_user_timeline( login, password, id, 'json', count )
    hash_data = JSON.parse( json_data )
    timeline = Array.new
    i = 0

    #debugger
    hash_data.each do |data|
      timeline[i] = Hash.new
      timeline[i][:name] = data['user']['name']
      timeline[i][:icon_url] = data['user']['profile_image_url']
      timeline[i][:text] = data['text']
      i += 1
    end
    timeline
  end

  # Twitter API - block follower
  # Returns user being blocked.
  # +login+ - id of twitter to use for authentication
  # +password+ - password for authenticating user
  # +id+ - id of twitter user to block
  # +type+ - type of encoding, 'xml' is default, can also be 'json', or 'rss'
  #
  def block( id, login=@login, password=@password, type='xml' )
    
    http = Net::HTTP.new('twitter.com', 80)
    data = http.start do |http_inst|
      path = "/blocks/create/#{id}.#{type}"
      req = Net::HTTP::Post.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
  end
 
  #
  # Twitter API - unblock follower
  # Returns user being unblocked.
  # +login+ - id of twitter to use for authentication
  # +password+ - password for authenticating user
  # +id+ - id of twitter user to block
  # +type+ - type of encoding, 'xml' is default, can also be 'json', or 'rss'
  #
  def unblock( id, login=@login, password=@password, type='xml' )
    
    http = Net::HTTP.new('twitter.com', 80)
    data = http.start do |http_inst|
      path = "/blocks/destroy/#{id}.#{type}"
      req = Net::HTTP::Post.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
  end
 
  # 
  # Returns a hash containing the profile for +twitter_id+.
  # +twitter_id+ is the name or integer id of a twitter user.
  #
  def get_profile( twitter_id )    
    data = Net::HTTP.get_response('twitter.com', "/users/show/#{twitter_id}.json").body
  
    # we convert the returned JSON data to native Ruby
    # data structure - a hash
    result = JSON.parse(data)
    
    # if the hash has 'Error' as a key, we raise an error
    if result.has_key? 'Error'
      raise "web service error"
    end
    result
  end
  
  # 
  # Returns the image URL from +account_profile+, a user profile hash.
  # +twitter_id+ is the integer id of a twitter user.
  #
  def get_image_url( account_profile )    
    account_profile['profile_image_url']
  end
  
  # Returns the image URL for the specified twitter id
  #
  def get_image_url_for_id( twitter_id )
    get_image_url( get_profile( twitter_id ) )
  end
  
  # 
  # Fetches the image specified by +image_url+ and saves it to +filename+.
  #
  def save_image_to_file( image_url, filename )
    image_uri = URI.parse( image_url )
    data = Net::HTTP.get_response( image_uri.host, image_uri.path ).body
    open( filename, 'w' ) do |f|
      f.write( data )
    end
  end
  
  #
  # Get Friends for specified id using the specified login credetials
  # Returns a hash
  #
  def get_friends( id, page=0, type='json', login=@login, password=@password )
    http = Net::HTTP.new('twitter.com', 80)
    json_data = http.start do |http_inst|
      path = "/statuses/friends/#{id}.#{type}?page=#{page}"
      req = Net::HTTP::Get.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
    hash_data = JSON.parse( json_data )
    
  end

  #
  # Get Followers for specified id using the specified login credetials
  # Returns a hash
  #
  def get_followers( id, login=@login, password=@password, type='json' )
    http = Net::HTTP.new('twitter.com', 80)
    results = []
    page = 1
    $stdout.sync = true
    print "Getting Followers.  Page "
    loop do
      json_data = http.start do |http_inst|
        path = "/statuses/followers/#{id}.#{type}?page=#{page}"
        print "#{page} "
        req = Net::HTTP::Get.new(path)
        # we make an HTTP basic auth by passing the
        # username and password
        req.basic_auth login, password
        resp, data = http_inst.request(req)
        data
      end 
      page_results = JSON.parse( json_data )
      break if page_results.length == 0
      results += page_results
      page += 1
    end
    puts 
    puts 
    results
  end

  #
  # Get Friends for specified id using the specified login credetials
  # Returns a hash
  #
  def get_friend_ids( id, login=@login, password=@password, type='json' )
    http = Net::HTTP.new('twitter.com', 80)
    json_data = http.start do |http_inst|
      path = "/friends/ids/#{id}.#{type}"
      req = Net::HTTP::Get.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
    hash_data = JSON.parse( json_data )
    
  end

  #
  # Get Followers for specified id using the specified login credetials
  # Returns a hash
  #
  def get_follower_ids( id, login=@login, password=@password, type='json' )
    http = Net::HTTP.new('twitter.com', 80)
    json_data = http.start do |http_inst|
      path = "/followers/ids/#{id}.#{type}"
      req = Net::HTTP::Get.new(path)
    
      # we make an HTTP basic auth by passing the
      # username and password
      req.basic_auth login, password
   
      resp, data = http_inst.request(req)
      data
    end
    hash_data = JSON.parse( json_data )
    
  end

  #
   # Destroy friend (unfollow)
   #
   def destroy_friend( id, login=@login, password=@password, type='json' )
     http = Net::HTTP.new('twitter.com', 80)
     json_data = http.start do |http_inst|
       path = "/friendships/destroy/#{id}.#{type}"
       req = Net::HTTP::Post.new(path)

       # we make an HTTP basic auth by passing the
       # username and password
       req.basic_auth login, password

       resp, data = http_inst.request(req)
       data
     end
     hash_data = JSON.parse( json_data )

   end
   
   def initialize( login=nil, password=nil )
     @login = login
     @password = password
   end

end # module Twitter

class TwitterProxy < TwitterAPI
end
