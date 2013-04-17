require 'interface_list.rb' do

class InterfaceLoader

  def self.load_interfaces(&callback)

    # FIXME: Load all the interfaces.
    
    interfaces = []
    
    files = Documentation::INTERFACE_FILE_NAMES
    unloaded_files = Hash[files.map { |o| [o, 1] }]
    files.each do |filename|
      load_interface(filename) do |interface|
        $window.console.log("Loaded interface: #{filename}")
        interfaces.push(interface) if interface
        unloaded_files.delete(filename)
        callback.call(interfaces) if unloaded_files.empty?
      end
    end
  end

  def self.load_interface(filename, &callback)
    request = XMLHttpRequest.new
    request.open('GET', filename)
    request.response_type = 'document'
    request.onreadystatechange do |event|
      if request.ready_state == XMLHttpRequest::DONE
        response = request.response_xml
        if response.nil?
          $window.console.log('nil for', filename)
        else
          interface = parse_interface_xml(response)
        end
        callback.call(interface)
      end
    end
    request.send()
  end

  def self.parse_interface_xml(xml)
    interface = {}

    interface_node = xml.query_selector('interface')
    interface[:name] = interface_node.attributes['name'].value
    interface[:description] = interface_node.query_selector('descr')
    interface[:interface_type] = :class

    attribute_nodes = xml.get_elements_by_tag_name('attribute')
    interface[:attributes] = attribute_nodes.map do |node|
      attribute = {}
      node_attributes = node.attributes
      attribute[:return_type] = node_attributes['type'].value
      attribute[:name] = node_attributes['name'].value
      attribute[:readonly] = !node_attributes['readonly'].nil?
      attribute[:description] = node.query_selector('descr')
      attribute[:interface_type] = :attribute
      attribute[:owner] = interface
      attribute
    end

    method_nodes = xml.get_elements_by_tag_name('method')
    interface[:methods] = method_nodes.map do |node|
      method = {}
      method[:name] = node.attributes['name'].value
      method[:description] = node.query_selector('descr')
      returns = node.query_selector('returns')
      method[:return_type] = returns.attributes['type'].value
      method[:return_description] = returns.query_selector('descr')
      method[:interface_type] = :method
      method[:owner] = interface      

      parameters = node.query_selector('parameters').get_elements_by_tag_name('param')
      method[:parameters] = parameters.map do |param_node|
        param = {}
        param[:name] = param_node.attributes['name'].value
        param[:type] = param_node.attributes['type'].value
        param[:attr] = param_node.attributes['attr'].value
        param[:description] = param_node.query_selector('descr')
        param
      end

      exceptions = node.query_selector('raises').get_elements_by_tag_name('exception')
      method[:exceptions] = exceptions.map do |exception_node|
        exception = {}
        exception[:name] = exception_node.attributes['name'].value
        exception[:description] = exception_node.query_selector('descr')
      end
      
      method
    end

    interface
  end

end # InterfaceDatabase

end # require