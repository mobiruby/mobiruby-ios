#!/usr/bin/env ruby

require 'rubygems'
require 'xcodeproj'
require 'nokogiri'

OUTPUT_FILE = ARGV[0]
PROJECT_FILE_PATH = ARGV[1] || ENV['PROJECT_FILE_PATH']
SDKROOT = ARGV[2] || ENV["SDKROOT"]
CFLAGS = ARGV[3] || ENV["OTHER_CFLAGS"] +
  " -D__IPHONE_OS_VERSION_MIN_REQUIRED=#{ENV['PLATFORM_VERSION_AVAILABILITY_H_FORMAT']}" +
  " -isysroot #{SDKROOT}"


$structs, $consts, $enum_values, $enum_names = {}, {}, [], []

def parse_bridgesupport(xml)
  doc = Nokogiri::XML(xml)

  doc.xpath('//struct').each do |s|
    # {.name = "CGPoint", .definition = "x:f:y:f"}
    dummy, name, type = /^\{([^=]+)="(.*)\}$/.match(s['type']).to_a
    type = type.gsub(/\{([^=]+)=[^}]*\}/, "{\\1}").gsub('"',':')
    $structs[name] = '    {.name="%s", .definition="%s"}' % [name, type]
  end

  doc.xpath('//constant').each do |c|
    $consts[c['name']] = '    {.name="%s", .type="%s", .value=(void*)&%s}' % [c['name'], c['type'], c['name']]
  end

  doc.xpath('//enum').each do |e|
    func = 'mrb_fixnum_value'
    func = 'mrb_float_value' if /[e\.]+/.match(e['value'])

    $enum_names << '    {.name="%s"}' % [e['name']]
    $enum_values << '    enums_table[%d].value = %s(%s);' % [$enum_values.count, func, e['value']]
  end

  # Todo: should support opaque
end

pr = Xcodeproj::Project.new(PROJECT_FILE_PATH)
frameworks = pr.groups.where(:name => 'Frameworks').children #.map{|a| File.join(SDKROOT, a.path)}

imports = []
frameworks.each do |fw|
  command = "/usr/bin/gen_bridge_metadata --no-64-bit -f \"#{File.join(SDKROOT, fw.path)}\" -c \"#{CFLAGS.gsub('"', "\\\"")} -framework #{fw.name.gsub('.framework', '')}\""

  xml = open("|#{command}").read
  imports += Dir.glob(File.join(SDKROOT, fw.path, 'Headers', '*.h')).map do |header|
    header.gsub(File.join(SDKROOT, fw.path, 'Headers'), fw.name.gsub('.framework', ''))
  end
  parse_bridgesupport(xml)
end

=begin
# Todo:
# source files does not support yet.
# I don't know how to get headers from xcodeproj

Dir.glob(File.join(File.dirname(PROJECT_FILE_PATH), "/**/*.h")) do |f|
  xml = open("|/usr/bin/gen_bridge_metadata -c\"-I#{File.dirname(f)} #{CFLAGS.gsub('"', "\\\"")}\" \"#{f}\"").read
  parse_bridgesupport(xml)
end
=end

open(OUTPUT_FILE, 'w').puts <<__STR__
/*
 Do not change this file.
 Generated from BridgeSupport.
*/
#include "cocoa.h"
#include "mruby/value.h"
#{imports.map{|i| "#import \"#{i}\""}.join("\n")}

static struct BridgeSupportStructTable structs_table[] = {
#{$structs.values.join(",\n")},
    {.name=NULL, .definition=NULL}
};

static struct BridgeSupportConstTable consts_table[] = {
#{$consts.values.join(",\n")},
    {.name=NULL, .type=NULL, .value=NULL}
};

static struct BridgeSupportEnumTable enums_table[] = {
#{$enum_names.join(",\n")},
    {.name=NULL}
};

void
init_cocoa_bridgesupport(mrb_state *mrb)
{
#{$enum_values.join("\n")}
    load_cocoa_bridgesupport(mrb, structs_table, consts_table, enums_table);
}

__STR__
