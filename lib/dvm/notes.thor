require "dnote"

class Notes < BuildTarget
protected
  def do_make(idetag, cfg)
    self.src_path.glob('**/{*.dproj}') do |f|
        inside(f.dirname.parent) do
          say "collecting notes for #{f.basename('.dproj')}..."
          catch_product(File.join(ROOT, f.basename('.dproj')) + '.notes.html') do |p|
            DNote::Session.main("-c", "7", "-m", "//", "-f", "html", "-t", "#{f.basename('.dproj')} Notes", "-o", "#{p}", "**/*.pas", "**/*.dpr", "**/*.ToDo.*")
          end
        end
     end
  end
end
