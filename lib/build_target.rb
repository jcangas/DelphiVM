
class BuildTarget < DvmTask
  attr_accessor :idetag
  attr_accessor :config
  attr_accessor :configs
  attr_accessor :platforms

  protected

  def self.depends(*task_names)
    @depends ||= []
    @depends.push(*task_names)
    @depends
  end

  def clear_products
    @products = []
  end

  def catch_products
    @catch_products = true
    yield
  ensure
    @catch_products = false
  end

  def catching_products?
    @catch_products
  end

  def catch_product(*prods)
    @products.push(*prods)
    yield(*prods) unless catching_products?
  end

  def do_clean(idetag, cfg)
    catch_products do
      do_make(idetag, cfg)
    end
    @products.each do |p|
      remove_file(p, verbose: false)
    end
  end

  def do_make(idetag, cfg)
  end

  def do_build(_idetag, _cfg)
    say_status '[clean]', ''
    invoke :clean
    say_status '[make]', ''
    invoke :make
  end

  def _build_path
    Pathname('out') + idetag
  end

  def self.publish
    super
    [:clean, :make, :build].each do |mth|
      desc "#{mth}", "#{mth} #{namespace} products"
      method_option :ide, type: :array, default: ['DEFIDE'], desc: "IDE list or ALL. #{IDEServices.default_ide} by default"
      method_option :props, type: :hash, aliases: '-p', default: configuration.build_args, desc: 'MSBuild properties. See MSBuild help'
      define_method mth do
        msbuild_params = options[:props]
        if options[:multi]
					if options[:ide].include?('DEFIDE')
	          ides_to_call = []
	        elsif options[:ide].map(&:upcase).include?('ALL')
	          ides_to_call = :all
	        end
          clear_products
          self.class.depends.each { |task| invoke "#{task}:#{mth}" }
          send("do_#{mth}", ides_to_call, msbuild_params)
        else
          if options[:ide].include?('DEFIDE')
            ides_to_call = [IDEServices.default_ide]
          elsif options[:ide].map(&:upcase).include?('ALL')
            ides_to_call = IDEServices.ides_in_prj
          else
            ides_to_call = IDEServices.ides_filter(options[:ide], :prj)
          end
          if ides_to_call.empty?
            IDEServices.report_ides(IDEServices.idelist(:prj), :prj)
            say "Error: cannot build for #{options[:ide]} IDEs"
          end
          ides_to_call.each do |idetag|
            self.idetag = idetag
            self.config = msbuild_params
            self.configs = IDEServices.configs_in_prj(idetag)
            self.platforms = IDEServices.platforms_in_prj(idetag)
            clear_products
            self.class.depends.each { |task| invoke "#{task}:#{mth}" }
            send("do_#{mth}", idetag, msbuild_params)
          end
        end
      end
    end
  end
end
