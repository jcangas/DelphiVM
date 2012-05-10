class ::Pathname 
  def glob(*args, &block)
    args[0] = (self + args[0]).to_s
    Pathname.glob(*args, &block)
  end

  def win
    self.to_s.gsub('/','\\')
  end
end

class String
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
