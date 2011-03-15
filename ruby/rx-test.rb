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

class TAP_Emitter
  attr_reader :i

  def ok(bool, desc)
    @i === nil ? @i = 1 : @i += 1
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

tap = TAP_Emitter.new

test_schema.keys.sort.each { |schema_name|
  rx  = Rx.new({ :load_core => true })

  schema_test_desc = test_schema[ schema_name ]

  if schema_test_desc['composedtype'] then
    begin
      rx.learn_type(schema_test_desc['composedtype']['uri'],
                     schema_test_desc['composedtype']['schema'])
    rescue Rx::Exception => e
      if schema_test_desc['composedtype']['invalid'] then
        tap.ok(true, "BAD COMPOSED TYPE: #{ schema_name }")
        next
      end

      throw e
    end

    if schema_test_desc['composedtype']['invalid'] then
      tap.ok(false, "BAD COMPOSED TYPE: #{ schema_name }")
      next
    end

    if schema_test_desc['composedtype']['prefix'] then
      rx.add_prefix(schema_test_desc['composedtype']['prefix'][0],
                    schema_test_desc['composedtype']['prefix'][1])
    end
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
      if entries == '*' then
        entries = test_data[source].keys
      end

      entries.each { |entry|
        result = schema.check(test_data[source][entry])
        ok = (pf == 'pass' and result) || (pf == 'fail' and !result)

        desc = sprintf "%s: %s/%s against %s",
          (pf == 'pass' ? 'VALID  ' : 'INVALID'), source, entry, schema_name

        tap.ok(ok, desc)
      }

      entries.each { |entry|
        result = begin 
                   schema.check!(test_data[source][entry])
                   true
                 rescue Rx::ValidationError => e
                   false
                 end
        ok = (pf == 'pass' and result) || (pf == 'fail' and !result)

        desc = sprintf "%s: %s/%s against %s",
          (pf == 'pass' ? 'VALID  ' : 'INVALID'), source, entry, schema_name

        tap.ok(ok, desc)
      }
    }
  }
}

puts "1..#{tap.i}"
