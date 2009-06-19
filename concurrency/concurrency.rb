#!/usr/bin/ruby
#
# Author: William D. Doughty 
# Date: 06/18/09
#

require 'thread'

class ThreadPool
  def initialize(size)
    @work = Queue.new
    @group = ThreadGroup.new
    @shutdown = false
    size.times do
      Thread.new do
        @group.add(Thread.current)
        Thread.stop
        loop do
          if @shutdown
            puts "#{Thread.current} stopping";
            Thread.current.terminate
          end
          job = @work.pop # threads wait here for a job
          args, block = *job
          begin
            block.call(*args)
          rescue StandardError => e
            bt = e.backtrace.join("\n")
            $stderr.puts "Error in thread (please catch this): #{e.inspect}\n#{bt}"
          end
          Thread.pass
        end
      end
    end
    @group.list.each { |w| w.run }
  end
 
  def add_job(*args, &block)
    puts "about to queue the job"
    @work << [args, block]
    self
    puts "job queued"
  end
 
  def shutdown(wait=true)
    @group.enclose
    @shutdown = true
    @group.list.first.join until @group.list.empty? if wait
  end
end

# class to manage a collection of BackgroundTasks.
class TaskCollection
  
  # adds a task to the collection. ordering of tasks is not preserved
  def << task
    loop do
      if @active_task_count > @pool_size
        @mutex.synchronize do
          @waiting.push Thread.current
        end
        puts "waiting on active task count #{@active_task_count} to fall below #{@pool_size}"
        sleep 10
      else
        break
      end
    end
    puts "setting the variables"
    @mutex.synchronize do
      @active_task_count += 1
      @collection << task
    end
    puts "setting the collection on the task"
    task.collection = self
    puts "calling run on the task"
    task.run( @thread_pool )
  end
  
  # returns the next finished task from the collection or nil if no tasks are left.
  # if all remaining tasks are still working, this method will wait until one finishes
  def next_finished
    @caller_thread = Thread.current
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
        @mutex.synchronize do
          @waiting.push Thread.current
        end
        sleep 10
      end
    end
    finished_task
  end
  
  def task_completed
    @mutex.synchronize do
      @active_task_count -= 1
      puts "Someone told the collection to wakeup."
      while thread = @waiting.shift do
        thread.wakeup
      end
    end
  end
  
  def initialize( size = 100 )
    @waiting = []
    @pool_size = size
    @thread_pool = ThreadPool.new( size )
    @mutex = Mutex.new
    @collection = []
    @active_task_count = 0
  end
end


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
    
    def run_block
      @mutex.synchronize do
        begin
          @result = @block.call
        rescue => exception
          @exception = exception
        end
        @finished = true
        if @collection
          @collection.task_completed
        end
      end
    end

  public
  
    # executes the block using the thread pool if provided or spawns a new thread if not.
    def run( thread_pool=nil )
      puts "checking and setting @scheduled"
      @mutex.synchronize do
        if @scheduled
          raise BackgroundTask::Error.new( "::run() called on #{self} more than once." )
        end
        @scheduled = true
      end
        if thread_pool 
          puts "running the task using the thread pool"
          thread_pool.add_job do
            run_block
          end
          puts "thread_pool job added."
        else
          thread = Thread.new do
            run_block
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
      @mutex.synchronize do
        if !@scheduled
          raise BackgroundTask::Error.new( ":result() called on #{self} that has not been run." )
        end
        raise @exception if @exception
        return @result
      end
    end
    
    # returns true if the task has finished.
    def finished
      @finished
    end
  
    # Creates a new BackgroundTask object and begins processing of the supplied Proc
    # immediately.  Call BackgroundTask::result() to retrieve the results.
    def initialize( &block )
      @block = block
      @collection = nil
      @finished = nil
      @caller = nil
      @scheduled = nil
      @mutex = Mutex.new
    end
end



