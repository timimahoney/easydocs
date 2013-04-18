require 'string_utils.rb' do

module InterfaceListItemView
  attr_accessor :interface

  def self.new
    obj = $window.document.create_element('li')
    obj.extend(self)
    obj.initialize_interface_list_item_view
    obj
  end

  def initialize_interface_list_item_view
    class_list.add('interface-list-item-view')

    @title = owner_document.create_element('h3')
    append_child(@title)

    @description = owner_document.create_element('div')
    @description.class_list.add('description')
    append_child(@description)

    @expand_button = owner_document.create_element('button')
    @expand_button.inner_text = 'Expand'
    @expand_button.onclick = method(:toggle_expand)
    append_child(@expand_button)
  end

  def interface=(interface)
    @interface = interface

    class_list.remove('class', 'method', 'attribute')
    class_list.add(interface[:interface_type].to_s)

    update_title()

    update_description()
  end

  def update_title
    @title.inner_html = ''
    type = interface[:interface_type]

    if type == :method or type == :attribute
      owner = interface[:owner]
      owner_text = owner_document.create_element('span')
      owner_text.class_list.add('owner')
      owner_string = prettify_owner(owner[:name])
      owner_text.inner_text = owner_string + '.'
      @title.append_child(owner_text)
    end

    case type 
    when :method
      method_signature = create_method_signature()
      @title.append_child(method_signature)
    when :attribute
      name = owner_document.create_element('span')
      name.inner_text = Documentation.underscore(interface[:name])
      @title.append_child(name)
    when :class
      @title.inner_text = interface[:name]
    end    
  end

  def create_method_signature
    signature = owner_document.create_element('span')
    signature.class_list.add('method_signature')
    method_name = owner_document.create_element('span')
    method_name.class_list.add('method_name')
    method_name.inner_text = Documentation.underscore(interface[:name])
    signature.append_child(method_name)
    open_parentheses = owner_document.create_element('span')
    open_parentheses.class_list.add('parentheses')
    open_parentheses.inner_text = '('
    signature.append_child(open_parentheses)

    parameters = owner_document.create_element('span')
    parameters.class_list.add('parameters')
    interface[:parameters].each do |parameter|
      param_span = owner_document.create_element('span')
      param_span.class_list.add('parameter')
      type = owner_document.create_element('span')
      type.class_list.add('type')
      type.inner_text = parameter[:type]
      param_span.append_child(type)
      name = owner_document.create_element('span')
      name.class_list.add('name')
      name.inner_text = parameter[:name]
      param_span.append_child(name)
      parameters.append_child(param_span)
    end
    signature.append_child(parameters)

    close_parentheses = owner_document.create_element('span')
    close_parentheses.class_list.add('parentheses')
    close_parentheses.inner_text = ')'
    signature.append_child(close_parentheses)

    signature
  end

  def update_description
    child = @description.first_child
    while child
      @description.remove_child(child)
      child = @description.first_child
    end

    if (interface[:description])
      description_node = interface[:description].clone_node(true)
      description_node.child_nodes.each { |node| @description.append_child(node) }
    end
  end

  def prettify_owner(owner_name)
    owner_name = Documentation.underscore(owner_name)
    owner_name.sub(/html_(.+)_element/, '\1')
  end

  def toggle_expand(event)
    $window.console.log('toggling expand')
    @description.class_list.toggle('expanded')
  end

end # InterfaceListItemView

end # require