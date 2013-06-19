require 'interface_list.rb' do

class InterfaceLoader

  def self.load_interfaces(&callback)
    load_webdocs_interfaces do |interfaces|
      callback.call(interfaces)
    end
  end

  private

  def self.load_webdocs_interfaces(&callback)
    request = XMLHttpRequest.new
    request.open('GET', '/data/interfaces.xml')
    request.response_type = 'document'
    request.onreadystatechange do |event|
      next if request.ready_state != XMLHttpRequest::DONE

      response = request.response_xml

      if response.nil?
        $window.console.log('Could not load interface data.')
        next
      end
      
      interfaces = parse_webdocs_interfaces(response)
      add_parent_interfaces(interfaces)
      callback.call(interfaces)
    end
    request.send()
  end

  def self.add_parent_interfaces(interfaces)
    interface_ids = interfaces.map { |interface| [interface[:id], interface] }
    interface_by_id = Hash[interface_ids]
    interfaces.each do |interface|
      parent = interface_by_id[interface[:parent_id]]
      next if !parent || parent[:id] == interface[:id]
      interface[:parent] = parent
    end
  end

  def self.parse_webdocs_interfaces(xml)
    interfaces = []

    interfaces_xml = xml.get_elements_by_tag_name('interface')
    interfaces_xml.each do |interface_xml|
      interface = parse_webdocs_interface_xml(interface_xml)
      interfaces.push(interface)
    end

    interfaces
  end

  def self.parse_webdocs_interface_xml(xml)
    interface = {}

    interface[:id] = xml.attributes['id'].value
    interface[:name] = xml.attributes['name'].value
    interface[:description] = xml.attributes['description'].value
    interface[:full_url] = xml.attributes[:full_url].value
    interface[:parent_id] = xml.attributes[:parent_id].value if xml.attributes[:parent_id]
    interface[:interface_type] = :class

    attribute_nodes = xml.get_elements_by_tag_name('property')
    interface[:attributes] = attribute_nodes.map do |node|
      attribute = parse_attribute(node)
      attribute[:owner] = interface
      attribute
    end

    method_nodes = xml.get_elements_by_tag_name('method')
    interface[:methods] = method_nodes.map do |node|
      method = parse_method(node)
      method[:owner] = interface      
      method
    end

    interface
  end

  def self.parse_attribute(node)
    attribute = {}
    attribute[:interface_type] = :attribute
    attribute[:id] = node.attributes['id'].value
    attribute[:type] = node.attributes['type'].value
    attribute[:name] = node.attributes['name'].value
    attribute[:readonly] = node.attributes['readonly'].value == 'true'
    attribute[:description] = node.attributes['description'].value
    attribute[:owner_id] = node.attributes['owner_id'].value
    attribute[:full_url] = node.attributes['full_url'].value
    attribute
  end

  def self.parse_method(node)
    method = {}
    method[:interface_type] = :method
    method[:id] = node.attributes['id'].value
    method[:name] = node.attributes['name'].value
    method[:return_type] = node.attributes['return_type'].value
    method[:description] = node.attributes['description'].value
    method[:return_description] = node.attributes['return_description'].value
    method[:owner_id] = node.attributes['owner_id'].value
    method[:full_url] = node.attributes['full_url'].value
    
    parameters = node.get_elements_by_tag_name('parameter')
    method[:parameters] = parameters.map do |parameter_node|
      parameter = {}
      parameter[:id] = parameter_node.attributes['id'].value
      parameter[:name] = parameter_node.attributes['name'].value
      parameter[:type] = parameter_node.attributes['type'].value
      parameter[:optional] = parameter_node.attributes['optional'].value == 'true'
      parameter[:description] = parameter_node.attributes['description'].value
      parameter[:full_url] = parameter_node.attributes['full_url'].value
      parameter[:owner_id] = parameter_node.attributes['owner_id'].value
      parameter
    end

    method
  end

  def load_xml_interfaces(&callback)
    files = Documentation::INTERFACE_FILE_NAMES
    unloaded_files = Hash[files.map { |o| [o, 1] }]
    files.each do |filename|
      load_interface(filename) do |interface|
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
        interface = parse_interface_xml(response) if response
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
      attribute[:interface_type] = :attribute
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
      method[:interface_type] = :method
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