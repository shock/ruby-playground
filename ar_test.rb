
require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :database => "buzzmanager_development",
  :username => "root",
  :password => ""
)

class Topic < ActiveRecord::Base
end

while true
  sleep 10
end