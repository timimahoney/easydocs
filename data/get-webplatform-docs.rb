require './web-platform-docs.rb'
require 'nokogiri'

p 'Requesting interfaces from WebPlatform.org...'
output_dir = ARGV[0] || './'

request_and_write_all(output_dir)
interfaces = load_interfaces_with_attached_members(output_dir)
# check_for_duplicates(interfaces)
builder = build_xml(interfaces)

p 'Outputting XML...'
File.open("#{output_dir}/interfaces.xml", 'w') do |file|
  file.write(builder.to_xml)
end