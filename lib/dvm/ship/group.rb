class Ship
	class Spec
		attr :name, true
		attr :version, true
		def initialize
			super()
			@groups = {}
			yield self if block_given?
		end

		def ignore_files(patterns)
				@ignore = [patterns].flatten
		end

		def bin_files(patterns)
				@groups[:bin] = [patterns].flatten
		end

		def lib_files(patterns)
				@groups[:lib] = [patterns].flatten
		end

		def source_files(patterns)
				@groups[:source] = [patterns].flatten
		end

		def doc_files(patterns)
				@groups[:doc] = [patterns].flatten
		end

		def sample_files(patterns)
				@groups[:sample] = [patterns].flatten
		end

		def test_files(patterns)
				@groups[:test] = [patterns].flatten
		end

		def get_zip_name(idever)
			Pathname("#{name}-#{version}-#{idever}.zip")
		end

		def get_zip_root
			Pathname("#{name}-#{version}")
		end

		def build(idever, outdir: '.', start: nil, progress: nil, zipping: nil, done: nil)
			self.vars = {idever: idever}
			zip_fname = Pathname(outdir) + get_zip_name(idever)
			zip_root = get_zip_root
			start.call(all_files.size) if start
		  Zip::File.open(zip_fname, Zip::File::CREATE) do |zipfile|
				all_files.each do |file|
			  	zip_entry = zip_root + file
			  	zipfile.add(zip_entry, file)
					progress.call(file) if progress
				end
				zipping.call if zipping
		  end
			done.call if done
		end

		def vars
			@vars
		end

	private

		def vars=(value)
			@vars = value
			@all_files = nil
		end

		def all_files
			return @all_files if @all_files
			ignore_files = @ignore.inject([]){|files, pattern| files + Pathname.glob(pattern % self.vars) }.uniq
			@all_files = @groups.values.inject([]) do |gfiles, patterns|
				gfiles + patterns.inject([]){|files, pattern| files + Pathname.glob(pattern % self.vars) - ignore_files }.uniq
			end.uniq
		end
	end

end
