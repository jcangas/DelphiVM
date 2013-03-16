class Vendor < Thor
  include Thor::Actions
  
  desc "init", "create and initialize vendor directory"
  def init
    vendor_path = PATH_TO_VENDOR
    empty_directory vendor_path
    empty_directory vendor_path + 'cache'
    empty_directory vendor_path + 'imports'
    create_file(DVM_IMPORTS_FILE, :skip => true) do <<-EOS
# sample imports file for delphivm

# first set source url
source "http://home.jcangas.info/ship"

# for each IDE version yo need
idever "D150" do
  # define some imports:
  import "SummerFW4D", "0.4.6"
end

# you can repeat it for other IDEs & sources

# source "#{PATH_TO_VENDOR}/local"
# etc..

EOS
    end
  end
  
  desc "import", "download and install vendor imports"
  method_option :clean,  type: :boolean, aliases: '-c', default: false, desc: "clean cache first"
  method_option :deploy,  type: :boolean, aliases: '-d', default: false, desc: "deploy after the import"
  def import
    clean_vendor(options) if options.clean?
    prepare
    silence_warnings{DSL.uses(DVM_IMPORTS_FILE)}
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
      copy_file(fname, ROOT + 'out' + fname)
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
