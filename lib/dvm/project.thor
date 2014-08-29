	
class Project < BuildTarget
	namespace :prj

	PRODUCT_ID = "#{::Delphivm::APPMODULE}-#{::Delphivm::APPMODULE.VERSION.tag}"

	desc  "clean", "clean #{APP_ID} products", :for => :clean
	desc  "make", "make #{APP_ID} products", :for => :make
	desc  "build", "build #{APP_ID} products", :for => :build

protected

	def do_clean(idetag, cfg)
		say_status("[#{idetag}] CLEAN:", "source res")
		clean_src_res_to_out(idetag)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Clean', cfg)
	end

	def do_make(idetag, cfg)
		say_status("[#{idetag}] MAKE:", "source res")
		make_src_res_to_out(idetag)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Make', cfg)
	end

	def do_build(idetag, cfg)
		say_status("[#{idetag}] BUILD:", "source res")
		clean_src_res_to_out(idetag)
		make_src_res_to_out(idetag)
		ide = IDEServices.new(idetag, ROOT)
		ide.call_build_tool('Build', cfg)
	end

	def make_src_res_to_out(idetag)
		(ROOT + 'out' + idetag + '*/*/lib/').glob.each do |p|
			(ROOT + 'src' + '**{.*,}/*.{dfm,fmx,res,dcr}').glob.each do |fsrc|
				get(fsrc.to_s, p + fsrc.basename, verbose: false)
			end
		end
	end

	def clean_src_res_to_out(idetag)
		(ROOT + 'out' + idetag + '*/*/lib/').glob.each do |p|
			(ROOT + 'src' + '**{.*,}/*.{dfm,fmx,res,dcr}').glob.each do |fsrc|
				remove_file(p + fsrc.basename, verbose: false)
			end
		end
	end

private
	def ides_in_prj
		IDEServices.ides_in_prj
	end

end
