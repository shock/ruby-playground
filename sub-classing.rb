class Test
  @value
  
  def method1
    puts "super-class method 1 - value = #{@value}"
  end
  
  def initialize
    @value = "super"
    puts "super class initialized"
    method1
  end
end

class Test
  # alias_method :initialize, :orig_initialize
  
  def initialize
    # orig_initialize
    @value = "sub"
    puts "sub class initialized"
    method1
  end
end

t = Test.new