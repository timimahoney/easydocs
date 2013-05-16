require './web-platform-docs.rb'
require 'nokogiri'

p 'Requesting interfaces from WebPlatform.org...'
output_dir = ARGV[0] || './'

# request_and_write_all(output_dir)

interfaces = read_json(filename: "#{output_dir}/interfaces.json")[:interfaces]
methods = read_json(filename: "#{output_dir}/methods.json")[:methods]
parameters = read_json(filename: "#{output_dir}/parameters.json")[:parameters]
properties = read_json(filename: "#{output_dir}/properties.json")[:properties]


p 'Mapping interfaces to IDs...'
id_to_interface = {}
interfaces.each do |interface|
  interface[:methods] = []
  interface[:properties] = []
  interface[:description] = convert_to_html(interface[:description])
  id_to_interface[interface[:id]] = interface
end


p 'Attaching properties to interfaces...'
properties.each do |property|
  property[:description] = convert_to_html(property[:description])

  # Some properties have multiple owners.
  owner_ids = property[:owner_id].split(',')
  owner_ids.each do |owner_id|
    interface = id_to_interface[owner_id]
    next if !interface
    this_property = property.clone
    interface[:properties].push(this_property)
  end
end


p 'Mapping methods to IDs...'
id_to_method = {}
methods.each do |method|
  method[:description] = convert_to_html(method[:description])
  id_to_method[method[:id]] = method
  method[:parameters] = []
end


p 'Attaching parameters to methods...'
parameters.each do |parameter|
  parameter[:description] = convert_to_html(parameter[:description])
  method = id_to_method[parameter[:owner_id]]
  method[:parameters].push(parameter)
end


p 'Attaching methods to interfaces...'
id_to_method = {}
methods.each do |method|
  # Some methods have multiple owners.
  owner_ids = method[:owner_id].split(',')
  owner_ids.each do |owner_id|
    interface = id_to_interface[owner_id]
    next if !interface
    this_method = method.clone
    interface[:methods].push(this_method)
  end
end

interface_names = {}
interfaces.each do |interface|
  if interface_names[interface[:name]]
    p "Duplicate: #{interface[:name]}. #{interface[:id]} #{interface_names[interface[:name]][:id]}"
  else
    interface_names[interface[:name]] = interface
  end
end


p 'Building XML...'
builder = Nokogiri::XML::Builder.new do |xml|
  xml.interfaces {
    interfaces.each do |interface|

      interface_attributes = {}
      interface_attributes[:id] = interface[:id]
      interface_attributes[:name] = interface[:name]
      interface_attributes[:description] = interface[:description]
      interface_attributes[:full_url] = interface[:full_url]      
      interface_attributes[:parent_id] = interface[:parent_id] if interface[:parent_id]

      xml.interface(interface_attributes) {

        xml.methods_ {

          interface[:methods].each do |method|
            method_attributes = {}
            method_attributes[:id] = method[:id]
            method_attributes[:name] = method[:name]
            method_attributes[:return_type] = method[:return_type]
            method_attributes[:owner_id] = method[:owner_id]
            method_attributes[:description] = method[:description]
            method_attributes[:full_url] = method[:full_url]
            xml.method_(method_attributes) {
              method[:parameters].each { |parameter| xml.parameter(parameter) }
            }
          end
        } # methods

        xml.properties {
          interface[:properties].each { |property| xml.property_(property) }
        } # properties

      }

    end # interfaces
  }
end

p 'Outputting XML...'
File.open("#{output_dir}/interfaces.xml", 'w') do |file|
  file.write(builder.to_xml)
end