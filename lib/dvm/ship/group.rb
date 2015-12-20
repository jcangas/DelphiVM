# Ship
class Ship
  # Spec
  class Spec
    attr_accessor :name
    attr_accessor :version
    def initialize
      super()
      @groups = []
      @files = {}
      yield self if block_given?
    end

    def ignore_files(patterns)
      @ignore = [patterns].flatten
    end

    def bin_files(patterns)
      @files[:bin] = [patterns].flatten
    end

    def lib_files(patterns)
      @files[:lib] = [patterns].flatten
    end

    def source_files(patterns)
      @files[:source] = [patterns].flatten
    end

    def doc_files(patterns)
      @files[:doc] = [patterns].flatten
    end

    def sample_files(patterns)
      @files[:samples] = [patterns].flatten
    end

    def test_files(patterns)
      @files[:test] = [patterns].flatten
    end

    def get_zip_name(idever)
      Pathname("#{name}-#{version}-#{idever}.zip")
    end

    def get_zip_root
      Pathname("#{name}-#{version}")
    end

    def build(idever, groups, outdir: '.', start: nil, progress: nil, zipping: nil, done: nil)
      self.vars = { idever: idever }
      @groups = groups
      reset_files
      zip_fname = Pathname(outdir) + get_zip_name(idever)
      zip_fname.dirname.mkpath
      zip_root = get_zip_root
      s = all_files.size
      all_files
      start.call(s) if start
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

    attr_reader :vars

    private

    def reset_files
      @all_files = nil
    end

    attr_writer :vars

    def all_files
      return @all_files if @all_files
      ignore_files = @ignore.inject([]) { |files, pattern| files + Pathname.glob(pattern % vars) }.uniq
      use_files = @files.select { |key, _value| @groups.empty? || @groups.include?(key.to_s) }
      @all_files = use_files.values.inject([]) do |collect_files, patterns|
        collect_files + patterns.inject([]) { |files, pattern| files + Pathname.glob(pattern % vars) - ignore_files }.uniq
      end.uniq
    end
  end
end
