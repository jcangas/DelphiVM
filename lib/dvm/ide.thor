# encoding: UTF-8

class Ide < Thor

  desc "list CRITERIA", "list IDEs info. CRITERIA=(config|installed|*prj) => delgpivm.cfg|this machine|this project"
  def list(kind = :prj)
    report_ides(IDEServices.idelist(kind), kind)
  end

  desc "start IDE-TAG  ", "start IDE with IDE-TAG"
  def start(idever=nil)
    idever ||= IDEServices.default_ide
    ide = IDEServices.new(idever, ROOT)
    ide.start 
  end

  desc "use IDE-TAG", "use IDE with IDE-TAG"
  def use(ide_tag)
    puts "Active path: " + IDEServices.use(ide_tag)
  end
  
  desc "test ", "internal use"
  def test
    IDEServices.platforms_in_prj
  end

private

  def report_ides(ides, kind = :found)
    say
    say "%30s IDEs: %d" % ["#{kind.to_s.upcase}", ides.size], :green, true
    infos = Delphivm::IDEInfos
    say "+%s-%s-%s+" % ['-'*7, '-'*12, '-'*42]
    say "| %5.5s | %10.10s | %40.40s |" % ['Tag', 'Name', 'Description']
    ides.map do |ide| 
      say "|%s+%s+%s|" % ['-'*7, '-'*12, '-'*42]
      say "| %5.5s | %10.10s | %40.40s |" % [ide.to_s, infos[ide][:name], infos[ide][:desc]]
    end
    say "+%s-%s-%s+" % ['-'*7, '-'*12, '-'*42]
  end

end
