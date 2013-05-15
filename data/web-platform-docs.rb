require 'net/http'
require 'json'

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
    interface[:parent_id]      = printouts['Subclass of'][0]['fulltext'] if printouts['Subclass of'][0]
    interface
  end

  interfaces.delete_if { |interface| !interface[:name] }
  interfaces
end

def write_json(hash: nil, filename: 'file.json')
  File.open(filename, 'w') do |file|
    file.write(JSON.dump(hash))
  end
end

def read_json(filename: 'file.json')
  File.open(filename) do |file|
    JSON.parse(file.read, { :symbolize_names => true })
  end
end

def request_methods
  methods = []
  limit = 100
  (0...7).each do |i|
    these_methods = request_methods_internal(limit: limit, offset: i * limit)
    methods += these_methods
  end

  methods
end

def request_methods_internal(limit: 100, offset: 0)
  p "Requesting methods #{offset} through #{offset + limit}..."
  results = request_results_for_query("[[Method_applies_to::~*]]|?Summary|?API_name|?Javascript_data_type|?Method_applies_to|limit=#{limit}|offset=#{offset}")
  methods = results.map do |id, data|
    printouts = data['printouts']
    method = {}
    method[:id]            = id
    method[:full_url]      = data['fullurl']
    method[:description]   = printouts['Summary'][0]
    method[:name]          = printouts['API name'][0]['fulltext'] if printouts['API name'][0]
    method[:return_type]   = printouts['Javascript data type'][0]
    method[:owner_id]      = printouts['Method applies to'][0]['fulltext']
    method
  end
  methods
end

def request_method_parameters
  parameters = []
  limit = 100
  (0...15).each do |i|
    these_parameters = request_method_parameters_internal(limit: limit, offset: i * limit)
    parameters += these_parameters
  end

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
  properties = []
  limit = 100
  (0...15).each do |i|
    these_properties = request_properties_internal(limit: limit, offset: i * limit)
    properties += these_properties
  end

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

def request_and_write_all
  interfaces = request_interfaces
  write_json(hash: { :interfaces => interfaces }, filename: 'interfaces.json')

  methods = request_methods
  write_json(hash: { :methods => methods }, filename: 'methods.json')

  parameters = request_method_parameters
  write_json(hash: { :parameters => parameters }, filename: 'parameters.json')

  properties = request_properties
  write_json(hash: { :properties => properties }, filename: 'properties.json')
end

def convert_to_html(description)
  return nil if !description
  description = description.gsub(/'[']+([^']+)'[']+/, '<code>\1</code>')
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
