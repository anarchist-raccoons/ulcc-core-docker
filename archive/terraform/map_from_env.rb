
# Create a hash from .env

require 'json'

f = File.read('../.env')

lines = f.split("\n")

hash = {}

lines.each do | l |
  next if l.start_with?('#') # skip comments rows
  next if l.nil? or l.empty?
  l = l.split('#').first if l.include?('#') # skip comments at end of rows
  # split on first equals
  kv = l.split('=')
  hash[kv[0]] = kv[1..kv.length-1].join('=')
end

puts hash.to_json
