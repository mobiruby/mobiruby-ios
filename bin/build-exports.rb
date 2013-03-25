#!/usr/bin/ruby

ENV['GEM_HOME'] = ENV['GEM_PATH'] = "/Library/Ruby/Gems/1.8"
require 'rubygems'
require 'nokogiri'

gem 'xcodeproj', '0.3.5'
require 'xcodeproj'

OUTPUT_FILE = ARGV[0]
PROJECT_FILE_PATH = ARGV[1] || ENV['PROJECT_FILE_PATH']
SDKROOT = ARGV[2] || ENV["SDKROOT"]
CFLAGS = ARGV[3] || ENV["OTHER_CFLAGS"] +
  " -D__IPHONE_OS_VERSION_MIN_REQUIRED=#{ENV['PLATFORM_VERSION_AVAILABILITY_H_FORMAT']}"

class BridgeMetadata
  attr_reader :consts, :enums, :structs

  def initialize(xml=nil)
    @consts, @enums, @structs = {}, {}, {}
    parse(xml) if xml
  end

  def parse(xml)
    doc = Nokogiri::XML(xml)

    doc.xpath('//struct').each do |s|
      # {.name = "CGPoint", .definition = "x:f:y:f"}
      dummy, name, type = /^\{([^=]+)="(.*)\}$/.match(s['type']).to_a
      type = type.gsub(/\{([^=]+)=[^}]*\}/, "{\\1}").gsub('"',':')
      @structs[name] = '    {.name="%s", .definition="%s"}' % [name.gsub(/^\w/) { |s| s.upcase }, type]
    end

    doc.xpath('//constant').each do |c|
     # @consts[c['name']] = '    {.name="%s", .type="%s", .value=(void*)&%s}' % [c['name'].gsub(/^\w/) { |s| s.upcase }, c['type'], c['name']]
      @consts[c['name']] = '    {.name="%s", .type="%s", .value=(void*)"%s"}' % [c['name'], c['type'], c['name']]
    end

    doc.xpath('//enum').each do |e|
      tt = 'u'
      val = [e['value'].to_i].pack('q')
      if /[e\.]+/.match(e['value'])
        tt = 'd'
        val = [e['value'].to_f].pack('d')
      elsif e['value'].to_i < 2^63
        tt = 's'
        val = [e['value'].to_i].pack('q')
      end
      @enums[e['name']] = %Q[    {.name="%s", .value={%s}, .type='%s'}] % [e['name'].gsub(/^\w/) { |s| s.upcase }, val.inspect, tt]
    end
  end

  def c_structs(name='structs_table', prefix='')
    %Q[
#{prefix} struct BridgeSupportStructTable #{name}[] = {
#{@structs.values.join(",\n")},
    {.name=NULL, .definition=NULL}
};
]
  end

  def c_enums(name='enums_table', prefix='')
    %Q[
#{prefix} struct BridgeSupportEnumTable #{name}[] = {
#{@enums.values.join(",\n")},
    {.name=NULL}
};
]
  end

  def c_consts(name='consts_table', prefix='')
    %Q[
#{prefix} struct BridgeSupportConstTable #{name}[] = {
#{@consts.values.join(",\n")},
    {.name=NULL}
};
]
  end
end

pr = Xcodeproj::Project.new(PROJECT_FILE_PATH)
frameworks = pr.groups.where(:name => 'Frameworks').children #.map{|a| File.join(SDKROOT, a.path)}

imports = []
metadata = BridgeMetadata.new

frameworks.each do |fw|
  command = %Q[/usr/bin/gen_bridge_metadata --no-64-bit -f "#{File.join(SDKROOT, fw.path)}" -c "#{CFLAGS.gsub('"', '\\"')} -isysroot "#{SDKROOT}" -framework #{fw.name.gsub('.framework', '')}"]

  xml = open("|#{command}").read
  imports += Dir.glob(File.join(SDKROOT, fw.path, 'Headers', '*.h')).map do |header|
    header.gsub(File.join(SDKROOT, fw.path, 'Headers'), fw.name.gsub('.framework', ''))
  end

  metadata.parse(xml)
end


open(OUTPUT_FILE, 'w').puts <<__STR__
/*
 Do not change this file.
 Generated from BridgeSupport.
*/
#include "cocoa.h"
#include "mruby/value.h"
#include <dlfcn.h>

#{imports.uniq.map{|i| "#import \"#{i}\""}.join("\n")}


#{metadata.c_structs(:structs_table, :static)}

#{metadata.c_enums(:enums_table, :static)}

#{metadata.c_consts(:consts_table, :static)}

void
init_cocoa_bridgesupport(mrb_state *mrb)
{
    void *dlh = dlopen(NULL, RTLD_LAZY);
    struct BridgeSupportConstTable *ccur = consts_table;
    while(ccur->name) {
        if(ccur->name == ccur->value) {
            ccur->value = dlsym(dlh, (const char*)ccur->value);
        }
        ++ccur;
    }
    dlclose(dlh);
    load_cocoa_bridgesupport(mrb, structs_table, consts_table, enums_table);
}

__STR__
