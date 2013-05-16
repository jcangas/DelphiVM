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
    tr("-", "_").
    downcase
  end

  def camelize
    self.split('_').map(&:capitalize).join
  end
end

module Kernel
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
