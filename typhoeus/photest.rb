require 'rubygems'
require 'typhoeus'
require 'json'
require 'base64'

# here's an example for twitter search
# Including Typhoeus adds http methods like get, put, post, and delete.
# What's more interesting though is the stuff to build up what I call
# remote_methods.
class TwitterSearch
  include Typhoeus
  remote_defaults :on_success => lambda {|response| JSON.parse(response.body)},
                  :on_failure => lambda {|response| puts "error code: #{response.code}"},
                  :base_uri   => "http://search.twitter.com"

  define_remote_method :search, :path => '/search.json'
  define_remote_method :trends, :path => '/trends/:time_frame.json'
  define_remote_method :followers, :path => '/statuses/followers.json'
end

class TwitterRestAPI
  include Typhoeus
  
  remote_defaults :on_success => lambda {|response| JSON.parse(response.body)},
                  :on_failure => lambda {|response| puts "error code: #{response.code}"},
                  :base_uri   => "http://twitter.com",
                  :headers => {"Authorization" => "Basic #{Base64.b64encode("buzzmanager_api:buzzshock")}"}

  define_remote_method :followers, :path => '/statuses/followers/:twitter_name.json', :headers => {"Authorization" => "Basic #{Base64.b64encode("buzzmanager_api:buzzshock")}"}
end

max_pages = 100
# here's and example of memoization
twitter_followers = []
1.upto max_pages do |page|
  twitter_followers << TwitterRestAPI.followers(:twitter_name => "oprah", :params => {:page=>page})
end

twitter_followers.each {|s| puts s.length}
  

tweets = TwitterSearch.search(:params => {:q => "railsconf"})

# if you look at the path argument for the :trends method, it has :time_frame.
# this tells it to add in a parameter called :time_frame that gets interpolated
# and inserted.
trends = TwitterSearch.trends(:time_frame => :current)

# and then the calls don't actually happen until the first time you
# call a method on one of the objects returned from the remote_method
# puts tweets.keys # it's a hash from parsed JSON

# you can also do things like override any of the default parameters
TwitterSearch.search(:params => {:q => "hi"}, :on_success => lambda {|response| puts response.body})

# on_success and on_failure lambdas take a response object. 
# It has four accesssors: code, body, headers, and time

# here's and example of memoization
twitter_searches = []
1.upto 15 do |page|
  twitter_searches << TwitterSearch.search(:params => {:q => "obama", :page=>page, :rpp=>100})
end

# this next part will actually make the call. However, it only makes one
# http request and parses the response once. The rest are memoized.
# twitter_searches.each {|s| puts s["results"].length}

