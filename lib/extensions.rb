class ::Pathname 
  def glob(*args, &block)
    args = [''] if args.empty?
    args[0] = (self + args[0]).to_s
    Pathname.glob(*args, &block)
  end

  def win
    self.to_s.gsub('/','\\')
  end
  
  def to_str
    win
  end
end

class String
  def snake_case
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    stripdup('\s|-', '_').
    downcase
  end

  #strip duplicates
  def stripdup(pattern, str=pattern,options=[:no_head, :no_trail])
    result = self.dup
    result.gsub!(/^(#{pattern})((#{pattern})*)/,"") if options.include?(:no_head)
    result.gsub!(/(#{pattern})((#{pattern})*)$/,"") if options.include?(:no_trail)
    result.gsub!(/(#{pattern})((#{pattern})*)/,"#{str}")
    result
  end

  def camelize(sep='')
    self.stripdup('\s|-', '_').split('_').map(&:capitalize).join(sep)
  end
end

## Thor silence_warnings
module Kernel
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
