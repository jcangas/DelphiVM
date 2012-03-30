class Vendor < Thor
  include Thor::Actions
  
  desc "init", "create and initialize vendor directory"
  def init
    vendor_path = PATH_TO_VENDOR
    empty_directory vendor_path
    empty_directory vendor_path + 'cache'
    empty_directory vendor_path + 'imports'
    create_file(vendor_path + 'vendor.dvm', :skip => true) do <<-EOS
# smaple vendor file

# first set source url
source 'http://home.jcangas.info/ship'

# then set your IDE version
idever 'D150'

# define some imports. 'Release' assumed by default: can be omitted
import "SummerFW4D", "0.4.6", config: 'Release' 

# you can repeat it for other IDEs

idever = 'D160'
import "SummerFW4D", "0.4.6", config: '*' # '*' => all configs 'Debug' and 'Release'
EOS
    end
  end
  
  desc "import", "download and install vendor imports"
  method_option :clean,  type: :boolean, aliases: '-c', default: false, desc: "clean cache first"
  method_option :deploy,  type: :boolean, aliases: '-d', default: false, desc: "deploy after the import"
  def import
    clean_vendor(options) if options.clean?
    prepare
    silence_warnings{DSL.uses(File.join(ROOT, 'vendor', 'vendor.dvm'))}
    deploy_vendor if options.deploy?
  end

  desc "clean", "Clean imports. Use -c (--cache) to also clean downloads cache"
  method_option :cache,  type: :boolean, aliases: '-c', default: false, desc: "also clean cache"
  def clean
    clean_vendor(options)
    prepare
  end

  desc "deploy", "deploy vendor bin files to project out dir"
  def deploy
    deploy_vendor
  end
  

private

  def deploy_vendor
    self.class.source_root PATH_TO_VENDOR_IMPORTS
    PATH_TO_VENDOR_IMPORTS.glob('**/bin/*.*') do |f|
      fname = f.relative_path_from(PATH_TO_VENDOR_IMPORTS)
      copy_file(fname, ROOT + 'OUT' + fname)
    end
  end

  def clean_vendor(opts)
    remove_dir(PATH_TO_VENDOR_IMPORTS)
    remove_dir PATH_TO_VENDOR_CACHE if opts.cache?
  end

  def prepare
    empty_directory PATH_TO_VENDOR_CACHE
    empty_directory PATH_TO_VENDOR_IMPORTS
  end	
end
