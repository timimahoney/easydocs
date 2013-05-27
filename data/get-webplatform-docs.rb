# This script will request and save the documentation needed from the WebPlatform API.
# Run it with 'ruby get-webplatform-docs.rb /path/to/output-directory'.
# It will output a few JSON files and one 'interfaces.xml' file in the output-directory.
# By default, the output directory is the current directory.
# The 'interfaces.xml' file is the one that is read by EasyDocs.

require './web-platform-docs.rb'
require 'nokogiri'

p 'Requesting interfaces from WebPlatform.org...'
output_dir = ARGV[0] || './'

request_and_write_all(output_dir)
interfaces = load_interfaces_with_attached_members(output_dir)
builder = build_xml(interfaces)

p 'Outputting XML...'
File.open("#{output_dir}/interfaces.xml", 'w') do |file|
  file.write(builder.to_xml)
end