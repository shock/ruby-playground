require 'rubygems'
require 'xml-object'
require 'pp'

#response = XMLObject.new( File.open('alexa-response.xml') )
response = XMLObject.new( File.open('test.xml') )

pp response
