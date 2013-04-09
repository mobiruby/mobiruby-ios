ENV['MRUBY_CONFIG'] = File.join(File.dirname(__FILE__), '..', 'build-libmruby.rb')

# https://gist.github.com/nayutaya/293358
module Enumerable
  def retry_if(*klasses)
    e = nil
    self.each { |arg|
      begin
        return yield(arg)
      rescue *klasses => e
        next
      end
    }
    raise(e)
  end
end

unless File.exists?('submodules/mruby/Rakefile')
  sh %Q{git submodule init}
  5.times.retry_if(RuntimeError) do
    raise unless system %Q{git submodule update}
  end
end
load 'submodules/mruby/Rakefile'

MRBC = File.expand_path('submodules/mruby/bin/mrbc')
DEBUG_APP_DIR = 'build/Debug-iphonesimulator/mobiruby-ios.app'

source_files = Dir.glob('src/**/*.rb')
file 'tmp/src.c' => source_files + [MRBC] do |t|
  FileUtils.mkdir_p 'tmp'
  FileUtils.rm_f t.name
  open(t.name, 'w') do |f|
    f.puts '#include <stdint.h>'
  end
  source_files.each do |filename|
    funcname = filename.relative_path_from('src').gsub('/','_').gsub(/\..*/, '')
    sh %Q{#{MRBC} -g -B"mruby_data_#{funcname}" -o- "#{filename}" >> #{t.name}}
  end
end

file DEBUG_APP_DIR => ['tmp/src.c', LIBMRUBY] do
  sh %Q{xcodebuild -configuration Debug -target mobiruby-ios -sdk iphonesimulator}
  sh %Q{touch "#{DEBUG_APP_DIR}"}
end

desc 'Clean your temporary files'
task :clean do
  Dir.glob('build/*').each do |f|
    FileUtils.rm_rf f
  end
end

def clear_task(name)
  task = Rake.application.lookup(name)
  task.clear
  task.instance_variable_set('@full_comment', nil)
end
clear_task :all
