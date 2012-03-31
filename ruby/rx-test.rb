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
    test_data[file][k] = JSON.parse("[ #{v} ]")[0]
  }
}

def normalize(entries, test_data)
  if entries == '*' then
    entries = { "*" => nil }
  end

  if entries.kind_of? Array then
    new_entries = { }
    entries.each { |n| new_entries[n] = nil }
    entries = new_entries
  end

  if entries.count == 1 and entries.has_key? '*' then
    value = entries["*"]
    entries = { }
    test_data.keys.each { |k| entries[k] = value }
  end

  return entries
end

class TAP_Emitter
  attr_reader :i
  attr_reader :failures

  def initialize()
    @failures = 0
  end

  def ok(bool, desc)
    @i === nil ? @i = 1 : @i += 1
    if ! bool then
      @failures += 1
    end
    printf("%s %s - %s\n", bool ? 'ok' : 'not ok', @i, desc);
  end
end

Find.find('spec/schemata') { |path|
  next unless File.file?(path)

  leaf = Pathname.new(path).
         relative_path_from( Pathname.new('spec/schemata') ).to_s

  leaf.sub!(/\.json$/, '')

  json = File.open(path).read
  test_schema[leaf] = JSON.parse(json)
}

rx  = Rx.new({ :load_core => true })
tap = TAP_Emitter.new

test_schema.keys.sort.each { |schema_name|
  schema_test_desc = test_schema[ schema_name ]

  if schema_test_desc['composed-type'] then
    next
  end

  begin
    schema = rx.make_schema(schema_test_desc['schema'])
  rescue Rx::Exception => e
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

  [ 'pass', 'fail' ].each { |pf|
    next unless schema_test_desc[pf]

    schema_test_desc[pf].each_pair { |source, entries|
      entries = normalize(entries, test_data[source])

      entries.each_pair { |entry, want|
        result = schema.check(test_data[source][entry])
        ok = (pf == 'pass' and result) || (pf == 'fail' and !result)

        desc = sprintf "%s: %s/%s against %s",
          (pf == 'pass' ? 'VALID  ' : 'INVALID'), source, entry, schema_name

        tap.ok(ok, desc)
      }

      entries.each_pair { |entry, want|
        result = begin
          schema.check!(test_data[source][entry])
          true
        rescue Rx::ValidationError => e
          false
        end
        ok = (pf == 'pass' and result) || (pf == 'fail' and !result)

        desc = sprintf "%s: %s-%s against %s",
          (pf == 'pass' ? 'VALID  ' : 'INVALID'), source, entry, schema_name

        tap.ok(ok, desc)
      }
    }
  }
}

puts "1..#{tap.i}"
exit(tap.failures > 0 ? 1 : 0)
