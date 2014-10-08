require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/rg'

$LOAD_PATH.unshift('lib', 'spec')
require 'delphivm'

if __FILE__ == $0
  Dir.glob('./spec/**/*_spec.rb') { |f| require f }
end
