require 'thread'
require 'fiddle'
require 'fiddle/import'
require 'win32ole'
require 'win32/registry.rb'

module User32
	extend Fiddle::Importer
	dlload 'user32'
	extern 'long SendMessageTimeout(long, long, long, void*, long, long, void*)'
end

module WinServices
	include Delphivm::Talk

	HWND_BROADCAST = 0xffff
	WM_SETTINGCHANGE = 0x001A
	SMTO_ABORTIFHUNG = 2

	def self.run_as(program, args, initial_dir=Dir.pwd)
		@shell ||= WIN32OLE.new('Shell.Application')
		# shell.ShellExecute(program, args, initial_dir, operation, show)
		@shell.ShellExecute(program, args, initial_dir, 'runas', 0)
	end

	def self.winpath=(path)
		run_as('reg', %Q{add "HKLM\\#{keyname}" /v PATH /d "#{path}" /f} )
		User32.SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment', SMTO_ABORTIFHUNG, 5000, 0)
		path
	end

	def self.mklink(link: nil, target: nil, **opts)
		raise "link arg is nil for mklink" unless link
		raise "target arg is nil for mklink" unless target
		args = []
		args << %Q("#{link}")
		args << %Q("#{target}")
		run_as('cmd', %Q(/c "mklink #{args.join(' ')}"))
	end

	def self.elevated?
		winshell(cmd: %Q(reg query "HKU\\S-1-5-19"), out_filter: lambda{|x|}, err_filter: lambda{|x|} ).success?
	end

	def self.reg_add(key: nil, value: nil, data: nil, **opts)
		args = []
		raise "key arg is nil for reg add" unless key
		args << %Q("#{key}")
		args << (value ? %Q(/v "#{value}") : "/ve")
		args << (data ? %Q(/d "#{data}") : nil)
		args << (opts[:force] ? "/f" : nil)
		args.compact!
		self.run_as('reg', %Q(add #{args.join(' ')}))
	end

	def self.reg_copy(source: nil, dest: nil, **opts)
		raise "source key arg is nil for reg copy" unless source
		raise "dest key arg is nil for reg copy" unless dest
		args = []
		args << %Q("#{source}")
		args << %Q("#{dest}")
		args << (opts[:recurse] ? "/s" : nil)
		args << (opts[:force] ? "/f" : nil)
		args.compact!
		self.run_as('reg', %Q(copy #{args.join(' ')}))
		%Q(reg copy #{args.join(' ')})
	end

	def self.system(cmd)
		%x(cmd)
	end

	def self.winshell(options = {})
		acmd = options[:cmd] || 'cmd /k'
		out_filter = options[:out_filter] || ->(line){true}
		err_filter = options[:err_filter] || ->(line){true}

		Open3.popen3(acmd) do |stdin, stdout, stderr, wait_thr|
			err_t = Thread.new(stderr) do |stm|
				while (line = stm.gets)
					say "STDERR: #{line}" if err_filter.call(line)
				end
			end

			out_t = Thread.new(stdout) do |stm|
				while (line = stm.gets)
					say "#{line}" if out_filter.call(line)
				end
			end

			begin
				yield stdin if block_given?
				stdin.close
				err_t.join
				out_t.join
				stdout.close
				stderr.close
			rescue Exception => excep
				say excep
			end
			wait_thr.value
		end
	end
end
