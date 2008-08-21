#!/usr/bin/ruby
require 'rubygems'
require 'json'

test_data   = { }
test_schema = { }

Dir.open('spec/data').each { |file|
  next if file =~ /\A\./

  json = File.open("spec/data/#{file}").read

  file.sub!(/\.json$/, '')

  test_data[file] = JSON.parse(json)
}

puts test_data
