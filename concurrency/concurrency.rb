#!/usr/bin/ruby
#
# Author: William D. Doughty 
# Date: 06/18/09
#
#
# Class to run a Proc in the background.
# Usage:
#   
# task = BackgroundTask.new do
#   # Do something IO intensive that blocks.
#   # An HTTP transaction, for instance.
#   # Then return the desired data in this block
#   "This is the data I expect my background task to return."
# end
# 
# puts task.result  # => "This is the data I expect my background task to return."
# 
# The block passed to the BackgroundTask::new begins execution immediately and control
# is returned to the current thread.
#
#  When BackgroundTask::result is called, it will block until the background task is finished.
#
# Thus, the ideal way to use BackgroundTask is to create multiple tasks for handling a
# set of IO requests in parallel, storing each task in an array.  Once all of the tasks have
# been created, the results can be processed in any order.  Even if calling
# BackgroundTask::result on an unfinished task blocks, the other tasks continue to execute
# in the background.  
#
# Eg. 
# 
# results = []
# tasks = []
# 1.upto 100 do |page|
#   task = BackgroundTask.new do 
#     http_get "twitter.com/statuses/followers/capbuzzman.json?page=#{page}"
#   end
#   tasks << task
# end
# tasks.each do |task|
#   results += task.result
# end
# results # contains array of results for all pages
#
class BackgroundTask
  
  class Error < RuntimeError; end
    
  private
    
  public
  
    def run
      if @thread
        raise BackgroundTask::Error.new( ":run() called more than once on #{self}." )
      else
        @thread = Thread.new do
          begin
            Thread.current[:result] = @block.call
          rescue => exception
            Thread.current[:exception] = exception
          end
          if @collection
            @collection.run
          end
        end
      end
    end

    def collection= collection
      @collection = collection
    end
    
    # Returns the results of the Proc passed to BackgroundTask::new().  
    # If the task has not finished,
    # execution of the current thread will block until it does.
    # If an exception occurrs while processing the Proc, it will be rethrown here.
    def result
      if !@thread
        raise BackgroundTask::Error.new( ":result() called on #{self}. that has never been run." )
      else
        @thread.join
        raise @thread[:exception] if @thread[:exception]
        return @thread[:result]
      end
    end
    
    # returns true if the task has finished.
    def finished
      # puts "#{@thread} - #{@thread.status}"
      return @thread.status == false
    end
  
    # Creates a new BackgroundTask object and begins processing of the supplied Proc
    # immediately.  Call BackgroundTask::result() to retrieve the results.
    def initialize ( &block )
      @block = block
      @collection = nil
    end
end

# class to manage a collection of BackgroundTasks.
class TaskCollection
  
  # adds a task to the collection. ordering of tasks is not preserved
  def << task
    task.collection = self
    @collection << task
    @mutex.synchronize do
      @active_task_count += 1
    end
    task.run
  end
  
  # returns the next finished task from the collection or nil if no tasks are left.
  # if all remaining tasks are still working, this method will wait until one finishes
  def next_finished
    @current_thread = Thread.current
    return nil if @collection.length == 0
    finished_task = nil
    while !finished_task do
      # puts "looping : #{@collection.length}"
      i=0
      @collection.each do |task|
        i+=1
        if task.finished
          # puts "Yes, it's finished #{i}"
          finished_task = @collection.delete(task)
          break
        else
          # puts "No, it's not finished #{i}"
        end
      end
      if @active_task_count > 0
        puts "sleeping with #{@active_task_count} tasks still running."
        sleep 10
      end
    end
    finished_task
  end
  
  def run
    if @current_thread
      @mutex.synchronize do
        @active_task_count -= 1
      end
      puts "Someone told the collection to run."
      @current_thread.run
    end
  end
  
  def initialize
    @mutex = Mutex.new
    @collection = []
    @active_task_count = 0
  end
end


