#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'

gem 'xcodeproj', '0.3.5'
require 'xcodeproj'

VERSIONS = {
  50000 => '5.0',
  50100 => '5.1',
  60100 => '5.0',
  60100 => '6.0',
  60100 => '6.1',
  60200 => '6.2',
  70000 => '7.0',
}
SDKROOT = ARGV[2] || ENV["SDKROOT"]
def sdkroot(version)
  File.join(File.dirname(SDKROOT), File.basename(SDKROOT).sub(/\d.*/, '')+VERSIONS[version]+".sdk")
end

VERSIONS.delete_if do |version, s|
  !File.exists?(sdkroot(version))
end

LATEST_VERSION = VERSIONS.keys.max

OUTPUT_FILE = ARGV[0]
PROJECT_FILE_PATH = ARGV[1] || ENV['PROJECT_FILE_PATH']

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
      @consts[c['name']] = '    {.name="%s", .type="%s", .value=(void*)&%s}' % [c['name'].gsub(/^\w/) { |s| s.upcase }, c['type'], c['name']]
    end

    doc.xpath('//enum').each do |e|
      tt = 'u'
      val = e['value'].to_i
      if /[e\.]+/.match(e['value'])
        tt = 'd'
        val = '0x' + [e['value'].to_f].pack('G').unpack('H*').first
      elsif e['value'].to_i < 2^63
        tt = 's'
        val = '0x' + [e['value'].to_i].pack('q').unpack('H*').first
      end
      @enums[e['name']] = %Q[    {.name="%s", .value={%s}, .type='%s'}] % [e['name'].gsub(/^\w/) { |s| s.upcase }, val, tt]
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
metadata = {}
VERSIONS.each do |version, version_str|
  metadata[version] = BridgeMetadata.new

  root = sdkroot(version)
  frameworks.each do |fw|
    command = %Q[/usr/bin/gen_bridge_metadata --no-64-bit -f "#{File.join(root, fw.path)}" -c "#{CFLAGS.gsub('"', '\\"')} -isysroot "#{root}" -framework #{fw.name.gsub('.framework', '')}"]

    xml = open("|#{command}").read
    imports += Dir.glob(File.join(root, fw.path, 'Headers', '*.h')).map do |header|
      header.gsub(File.join(root, fw.path, 'Headers'), fw.name.gsub('.framework', ''))
    end

    metadata[version].parse(xml)
  end
end



=begin
# Todo:
# source files does not support yet.
# I don't know how to get headers from xcodeproj

Dir.glob(File.join(File.dirname(PROJECT_FILE_PATH), "/**/*.h")) do |f|
  xml = open("|/usr/bin/gen_bridge_metadata -c\"-I#{File.dirname(f)} #{CFLAGS.gsub('"', "\\\"")}\" \"#{f}\"").read
  parse_bridgesupport(xml)
end



#{metadata.c_consts(:consts_table, :static)}

=end

open(OUTPUT_FILE, 'w').puts <<__STR__
/*
 Do not change this file.
 Generated from BridgeSupport.
*/
#include "cocoa.h"
#include "mruby/value.h"

#{imports.uniq.map{|i| "#import \"#{i}\""}.join("\n")}


#{metadata[LATEST_VERSION].c_structs(:structs_table, :static)}

#{metadata[LATEST_VERSION].c_enums(:enums_table, :static)}

#{
  VERSIONS.keys.sort.map { |version|
    vs = metadata[version].consts.length
    if LATEST_VERSION != version
      (metadata[version].consts.keys - metadata[LATEST_VERSION].consts.keys).each do |key|
        metadata[version].consts.delete key
      end
    end
    "static struct BridgeSupportConstTable* consts_table_%d() {\n%s\n  return consts_table;\n}" % [
      version,
      metadata[version].c_consts("consts_table", "    ")
    ]
  }.join("\n")
}

static int getSystemVersionAsAnInteger()
{
    int index = 0;
    NSInteger version = 0;

    NSArray* digits = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    NSEnumerator* enumer = [digits objectEnumerator];
    NSString* number;
    while (number = [enumer nextObject]) {
        if (index>2) {
            break;
        }
        NSInteger multipler = powf(100, 2-index);
        version += [number intValue]*multipler;
        index++;
    }
  return version;
}

void
init_cocoa_bridgesupport(mrb_state *mrb)
{
    static struct BridgeSupportConstTable *consts_table = NULL;
    if(consts_table == NULL) {
        consts_table = consts_table_#{LATEST_VERSION}();
        int ios_ver = getSystemVersionAsAnInteger();

        #{
VERSIONS.keys.sort.reverse.map do |version|
  "if(ios_ver >= #{version}) { consts_table = consts_table_#{version}(); }"
end.join("\n        else ")
}
        else {
            NSLog(@"don't support this version");
        }
        NSLog(@"consts_table=%p", consts_table);
    }
    load_cocoa_bridgesupport(mrb, structs_table, consts_table, enums_table);
}

__STR__
