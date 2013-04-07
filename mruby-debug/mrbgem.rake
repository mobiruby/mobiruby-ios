MRuby::Gem::Specification.new('mruby-debug') do |spec|
  spec.license = 'MIT'
  spec.authors = 'MobiRuby developers'
 
  # Add compile flags
  # spec.cc.flags << ''

  # Add cflags to all
  spec.mruby.cc.defines << 'ENABLE_DEBUG'
  spec.cc.defines << 'ENABLE_DEBUG'
  # spec.mruby.cc.defineds << ''

  # Add libraries
  # spec.linker.libraries << 'external_lib'

  # Default building fules
  # spec.rbfiles = Dir.glob("#{dir}/mrblib/*.rb")
  # spec.objs = Dir.glob("#{dir}/src/*.{c,cpp,m,asm,S}").map { |f| objfile(f.relative_path_from(dir).pathmap("#{build_dir}/%X")) }
  # spec.test_rbfiles = Dir.glob("#{dir}/test/*.rb")
  # spec.test_objs = Dir.glob("#{dir}/test/*.{c,cpp,m,asm,S}").map { |f| objfile(f.relative_path_from(dir).pathmap("#{build_dir}/%X")) }
  # spec.test_preload = 'test/assert.rb'
end
