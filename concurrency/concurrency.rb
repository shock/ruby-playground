#!/usr/bin/ruby
#
# Author: William D. Doughty 
# Date: 06/18/09
#

def nputs message
  # puts message
end

require 'thread'


## This is currently not working.  Causes a deadlock.  
#
class BoundedQueue < Queue
  
  def wakeup_waiting_threads
    while thread = @waiting.shift do
      thread.wakeup
    end
  end
  
  def pop
    @mutex.synchronize do
      if @count > 0
        @count -= 1
        wakeup_waiting_threads
      end
    end
    super
  end
  
  def push
    loop do
        if @count >= @size
          @waiting << Thread.current
          sleep 10
        else
          super
          break
        end
      end
  end
  
  def initialize( size )
    @mutex = Mutex.new
    @count = 0
    @size = size
    @waiting = []
    super
  end
end


class ThreadPool
  def initialize(size)
    @size = size
    @work = Queue.new
    @group = ThreadGroup.new
    @shutdown = false
    size.times do
      Thread.new do
        @group.add(Thread.current)
        Thread.stop
        loop do
          if @shutdown
            nputs "#{Thread.current} stopping"
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
    @work << [args, block]
    self
  end
 
  def shutdown(wait=true)
    @group.enclose
    @shutdown = true
    @group.list.first.join until @group.list.empty? if wait
  end
end

# Class to manage scheduling of a collection of BackgroundTasks.
class TaskCollection
  
  # Queues the supplied background task for execution.
  def << task
    loop do
      if @active_task_count > @pool_size
        @mutex.synchronize do
          @waiting.push Thread.current
        end
        Thread.stop
      else
        break
      end
    end
    @mutex.synchronize do
      @active_task_count += 1
      task.collection = self
      @collection << task
      task.run( @thread_pool )
    end
  end
  
  # Creates a background task for the supplied block of code and queues it for execution
  def add_task &block
    self << BackgroundTask.new( &block )
  end
    
  
  # Returns the next finished task from the collection or nil if no tasks remain.
  # If all remaining tasks are still working, this method will block until one finishes
  def next_finished
    return nil if @collection.length == 0
    finished_task = @finished_queue.pop  # blocks if queue is empty
    @mutex.synchronize do
      @collection.delete(finished_task)
    end
    finished_task
  end
  
  # This method should not be called directly.  Each background task calls this method to notify
  # the collection that it has finished.
  def task_completed task
    @mutex.synchronize do
      @active_task_count -= 1
    end
    @finished_queue.push task
    while thread = @waiting.shift
      thread.wakeup
    end
  end
  
  # Returns true if any remaining tasks have finished, false otherwise
  def task_ready?
    !@finished_queue.empty?
  end
  
  def initialize( collection_size = 100, thread_pool=nil )
    @waiting = []
    @pool_size = collection_size
    @thread_pool = thread_pool || ThreadPool.new( collection_size )
    @mutex = Mutex.new
    @collection = []
    @active_task_count = 0
    @finished_queue = Queue.new
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
# nputs task.result  # => "This is the data I expect my background task to return."
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
        @block = nil
        @finished = true
        if @collection
          @collection.task_completed self
        end
      end
    end

  public
  
    # executes the block using the thread pool if provided or spawns a new thread if not.
    def run( thread_pool=nil )
      @mutex.synchronize do
        if @scheduled
          raise BackgroundTask::Error.new( "::run() called on #{self} more than once." )
        end
        @scheduled = true
        if thread_pool 
          thread_pool.add_job do
            run_block
          end
        else
          thread = Thread.new do
            run_block
          end
        end
      end
    end

    def collection= collection
      @collection = collection
    end
    
    # Returns the result of executing the Proc supplied to the constructor.
    # If execution has not finished, this method will block until it has.
    # If an exception occurred while executing the Proc, it will be rethrown here.
    def result
      nputs "************ here1"
      @mutex.synchronize do
        nputs "************ here2"
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
  
    # Creates a new BackgroundTask object containing the supplied Proc.
    # Use BackgroundTask::result() to retrieve the result.
    def initialize( &block )
      @block = block
      @collection = nil
      @finished = nil
      @caller = nil
      @scheduled = nil
      @mutex = Mutex.new
    end
end



