require 'net/http'
require 'json'
require 'active_support/all'
require 'nokogiri'

API_BASE_URL = 'http://docs.webplatform.org/w/api.php?format=json&action=ask&query='

def request_interfaces
  p 'Requesting interfaces...'
  results = request_results_for_query('[[Category:API Objects]]|?Summary|?API_name|?Subclass_of|limit=1000')

  interfaces = results.map do |id, data|
    printouts = data['printouts']
    interface = {}
    interface[:id]             = id
    interface[:full_url]       = data['fullurl']
    interface[:description]    = printouts['Summary'][0]
    interface[:name]           = printouts['API name'][0]['fulltext'] if printouts['API name'][0]
    interface[:name]           = interface[:name].split('.').last.camelize if interface[:name]
    interface[:parent_id]      = printouts['Subclass of'][0]['fulltext'] if printouts['Subclass of'][0]
    interface
  end

  interfaces.delete_if { |interface| !interface[:name] }

  bad_interfaces = ['dom/apis/document', 'dom/apis/window']
  interfaces.delete_if { |interface| bad_interfaces.include? interface[:id] }
  interfaces
end

def write_json(hash: nil, filename: 'file.json')
  File.open(filename, 'w') do |file|
    file.write(JSON.pretty_generate(hash))
  end
end

def read_json(filename: 'file.json')
  File.open(filename) do |file|
    JSON.parse(file.read, { :symbolize_names => true })
  end
end

def request_methods
  limit = 100
  threads = []
  (0...7).each do |i|
    threads << Thread.new { request_methods_internal(limit: limit, offset: i * limit) }
  end

  methods = threads.flat_map(&:value)
  methods
end

def request_methods_internal(limit: 100, offset: 0)
  p "Requesting methods #{offset} through #{offset + limit}..."
  results = request_results_for_query("[[Method_applies_to::~*]]|?Summary|?API_name|?Javascript_data_type|?Method_applies_to|?Return_value_description|limit=#{limit}|offset=#{offset}")
  methods = results.map do |id, data|
    printouts = data['printouts']
    method = {}
    method[:id]                 = id
    method[:full_url]           = data['fullurl']
    method[:description]        = printouts['Summary'][0]
    method[:name]               = printouts['API name'][0]['fulltext'] if printouts['API name'][0]
    method[:return_type]        = printouts['Javascript data type'][0]
    method[:return_description] = printouts['Return value description'][0]
    method[:owner_id]           = printouts['Method applies to'][0]['fulltext']
    method
  end
  methods
end

def request_method_parameters
  threads = []
  limit = 100
  (0...15).each do |i|
    threads << Thread.new { request_method_parameters_internal(limit: limit, offset: i * limit) }
  end

  parameters = threads.flat_map(&:value)
  parameters
end

def request_method_parameters_internal(limit: 100, offset: 0)
  p "Requesting parameters #{offset} through #{offset + limit}..."
  results = request_results_for_query("[[Parameter_for_method::~*]]|?Javascript_data_type|?Parameter_description|?Parameter_name|?Parameter_optional|?Parameter_for_method|limit=#{limit}|offset=#{offset}")
  parameters = results.map do |id, data|
    printouts = data['printouts']
    parameter = {}
    parameter[:id]            = id
    parameter[:full_url]      = data['fullurl']
    parameter[:name]          = printouts['Parameter name'][0]
    parameter[:description]   = printouts['Parameter description'][0]
    parameter[:optional]      = printouts['Parameter optional'][0] == 't'
    parameter[:type]          = printouts['Javascript data type'][0]
    parameter[:owner_id]      = printouts['Parameter for method'][0]['fulltext']
    parameter
  end
  parameters
end

def request_properties
  threads = []
  limit = 100
  (0...15).each do |i|
    threads << Thread.new { request_properties_internal(limit: limit, offset: i * limit) }
  end

  properties = threads.flat_map(&:value)
  properties
end

def request_properties_internal(limit: 100, offset: 0)
  p "Requesting properties #{offset} through #{offset + limit}..."
  results = request_results_for_query("[[Property_applies_to::~*]]|?Javascript_data_type|?Summary|?API_name|?Read_only|?Property_applies_to|limit=#{limit}|offset=#{offset}")
  properties = results.map do |id, data|
    printouts = data['printouts']
    property = {}
    property[:id]            = id
    property[:full_url]      = data['fullurl']
    property[:name]          = printouts['API name'][0]['fulltext']
    property[:description]   = printouts['Summary'][0]
    property[:readonly]      = printouts['Read only'][0] == 't'
    property[:type]          = printouts['Javascript data type'][0]
    property[:owner_id]      = printouts['Property applies to'][0]['fulltext']
    property
  end
  properties
end

def request_results_for_query(query)
  url = API_BASE_URL + URI::escape(query)
  uri = URI(url)
  response = Net::HTTP.get(uri)
  json = JSON.parse(response)
  results = json['query']['results']
  results
end

def request_and_write_all(output_dir)
  interfaces = request_interfaces
  write_json(hash: { :interfaces => interfaces }, filename: "#{output_dir}/interfaces.json")

  methods = request_methods
  write_json(hash: { :methods => methods }, filename: "#{output_dir}/methods.json")

  parameters = request_method_parameters
  write_json(hash: { :parameters => parameters }, filename: "#{output_dir}/parameters.json")

  properties = request_properties
  write_json(hash: { :properties => properties }, filename: "#{output_dir}/properties.json")
end

def convert_to_html(description)
  return nil if !description
  description.gsub!(/'[']+([^']+)'[']+/, '<code>\1</code>')
  description.gsub!(/\[\[([^|]+)\|([^\]]+)\]\]/, '<a class=\'webplatform-link\' data-webplatform-url=\'\1\'><code>\2</code></a>')
  nbsp = Nokogiri::HTML("&nbsp;").text
  description.gsub!(nbsp, '')


  paragraphs = description.split("\n")

  elements = []
  in_list = false
  paragraphs.each do |p|
    if p[0] == '*'
      elements.push('<ul>') if !in_list
      in_list = true
      p = p[1..p.size - 1].strip
      elements.push("<li>#{p}</li>")
    else
      elements.push('</ul>') if in_list
      in_list = false
      elements.push("<p>#{p}</p>")
    end
  end
  elements.push('</ul>') if in_list
  elements.join('')
end

TYPE_REPLACEMENTS = { 'DOM Node' => 'Node',
                      'Boolean'  => 'boolean' }

def replace_type_name_if_needed(typename)
  TYPE_REPLACEMENTS[typename] || typename
end

def load_interfaces_with_attached_members(output_dir)
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
    property[:type] = replace_type_name_if_needed(property[:type])

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
    method[:return_description] = convert_to_html(method[:return_description])
    method[:return_type] = replace_type_name_if_needed(method[:return_type])
    id_to_method[method[:id]] = method
    method[:parameters] = []
  end


  p 'Attaching parameters to methods...'
  parameters.each do |parameter|
    parameter[:description] = convert_to_html(parameter[:description])
    parameter[:type] = replace_type_name_if_needed(parameter[:type])
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

  interfaces
end

def check_for_duplicates(interfaces)
  interface_names = {}
  interfaces.each do |interface|
    if interface_names[interface[:name]]
      p "Duplicate: #{interface[:name]}. #{interface[:id]} #{interface_names[interface[:name]][:id]}"
    else
      interface_names[interface[:name]] = interface
    end
  end
end

def build_xml(interfaces)
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
              method_attributes[:return_description] = method[:return_description]
              method_attributes[:full_url] = method[:full_url]
              xml.method_(method_attributes) {

                method[:parameters].each do |parameter|
                  parameter_attributes = {}
                  parameter_attributes[:id] = parameter[:id]
                  parameter_attributes[:name] = parameter[:name]
                  parameter_attributes[:type] = parameter[:type]
                  parameter_attributes[:owner_id] = parameter[:owner_id]
                  parameter_attributes[:description] = parameter[:description]
                  parameter_attributes[:optional] = parameter[:optional]
                  parameter_attributes[:full_url] = parameter[:full_url]
                  xml.parameter(parameter_attributes)
                end
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
  
  builder
end