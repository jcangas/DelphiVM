
class Ide < Thor

  desc "list", "show instaled IDE versions"
  def list
    report_ides IDEServices.idelist
  end

  desc "used", "current used IDE versions"
  def used
    report_ides IDEServices.ideused
  end

  desc "start IDEVER  ", "start IDE IDEVER"
  def start(idever)
    ide = IDEServices.new(idever, ROOT)
    ide.start 
  end

private

  def report_ides(ides)
    if ides.empty?
      say "NO IDE(s) found\n"
    else
      say "found IDEs:\n"
      say ides.join("\n")
    end
  end

end
