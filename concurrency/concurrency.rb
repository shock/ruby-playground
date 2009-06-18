#!/usr/bin/ruby
#
# Author: William D. Doughty 
# Date: 06/18/09
#
#
# Class to run a Proc in the background.
# Usage:
#   
# job = BackgroundJob.new do
#   # Do something IO intensive that blocks.
#   # An HTTP transaction, for instance.
#   # Then return the desired data in this block
#   "This is the data I expect my background job to return."
# end
# 
# puts job.result  # => "This is the data I expect my background job to return."
# 
# The block passed to the BackgroundJob::new begins execution immediately and control
# is returned to the current thread.
#
#  When BackgroundJob::result is called, it will block until the background job is finished.
#
# Thus, the ideal way to use BackgroundJob is to create multiple jobs for handling a
# set of IO requests in parallel, storing each job in an array.  Once all of the jobs have
# been created, the results can be processed in any order.  Even if calling
# BackgroundJob::result on an unfinished job blocks, the other jobs continue to execute
# in the background.  
#
# Eg. 
# 
# results = []
# jobs = []
# 1.upto 100 do |page|
#   job = BackgroundJob.new do 
#     http_get "twitter.com/statuses/followers/capbuzzman.json?page=#{page}"
#   end
#   jobs << job
# end
# jobs.each do |job|
#   results += job.result
# end
# results # contains array of results for all pages
#
class BackgroundJob
  
  class Error < RuntimeError; end
    
  private
    
    def run
      if @thread
        raise BackgroundJob::Error.new( ":run() called more than once on #{self}." )
      else
        @thread = Thread.new do
          begin
            Thread.current[:result] = @block.call
          rescue => exception
            Thread.current[:exception] = exception
          end
        end
      end
    end
  
  public
    
    # Returns the results of the Proc passed to BackgroundJob::new().  
    # If the job has not finished,
    # execution of the current thread will block until it does.
    # If an exception occurrs while processing the Proc, it will be rethrown here.
    def result
      if !@thread
        raise BackgroundJob::Error.new( ":result() called on #{self}. that has never been run." )
      else
        @thread.join
        raise @thread[:exception] if @thread[:exception]
        return @thread[:result]
      end
    end
  
    # Creates a new BackgroundJob object and begins processing of the supplied Proc
    # immediately.  Call BackgroundJob::result() to retrieve the results.
    def initialize ( &block )
      @block = block
      run
    end
end

