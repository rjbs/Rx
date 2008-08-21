#!/usr/bin/ruby
require 'find'
require 'pathname'
require 'rubygems'
require 'json'

require './ruby/Rx.rb'

test_data   = { }
test_schema = { }

Dir.open('spec/data').each { |file|
  next if file =~ /\A\./

  json = File.open("spec/data/#{file}").read

  file.sub!(/\.json$/, '')

  test_data[file] = JSON.parse(json)

  if test_data[file].instance_of?(Array) then
    new_data = { }
    test_data[file].each { |e| new_data[e] = e }
    test_data[file] = new_data
  end

  test_data[file].each_pair { |k,v|
    boxed = JSON.parse("[ #{ v } ]")
    test_data[file][k] = boxed[0]
  }
}

class TAP_Emitter
  def ok(bool, desc)
    @i = 0 if @i === nil
    @i += 1
    printf("%s %s %s\n", bool ? 'ok' : 'not ok', @i, desc);
  end
end

Find.find('spec/schemata') { |path|
  next unless File.file?(path)

  leaf = Pathname.new(path).
         relative_path_from( Pathname.new('spec/schemata') ).
         to_s

  leaf.sub!(/\.json$/, '')

  json = File.open(path).read
  test_schema[leaf] = JSON.parse(json)
}

rx = Rx.new
tap = TAP_Emitter.new

test_schema.keys.sort.each { |schema_name|
  schema_test_desc = test_schema[ schema_name ]

  begin
    schema = rx.make_schema(schema_test_desc['schema'])
  rescue Rx::Error => e
    if schema_test_desc['invalid'] then
      tap.ok(true, "BAD SCHEMA: #{ schema_name }")
      next
    end

    throw e
  end

  if not schema then
    tap.ok(false, "no schema for valid input (#{schema_name})")
    next
  end

  if schema_test_desc['invalid'] then
    tap.ok(false, "BAD SCHEMA: #{ schema_name }")
    next
  end
}

# puts test_data.inspect
# puts test_schema.inspect
