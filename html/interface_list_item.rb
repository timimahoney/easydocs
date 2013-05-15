require 'string_utils.rb' do

module InterfaceListItem
  CLICKED_INTERFACE = 'clicked interface'

  attr_accessor :interface
  attr_accessor :show_parent_class
  attr_accessor :is_header_clickable

  def self.new
    obj = $window.document.create_element('li')
    obj.extend(self)
    obj.initialize_interface_list_item
    obj
  end

  def interface=(interface)
    @interface = interface

    class_list.remove('class', 'method', 'attribute')
    class_list.add(interface[:interface_type].to_s)

    update_header
    update_description
    update_declaration
    update_info
  end

  def show_parent_class=(show_parent_class)
    @show_parent_class = show_parent_class
    if @show_parent_class
      class_list.add('show-parent')
    else
      class_list.remove('show-parent')
    end
  end

  def is_header_clickable=(is_clickable)
    @is_header_clickable = is_clickable

    if @is_header_clickable
      class_list.add('clickable')
    else
      class_list.remove('clickable')
    end
  end

  def initialize_interface_list_item
    class_list.add('interface-list-item')

    @title_container = owner_document.create_element('div')
    @title_container.class_list.add('interface-header')
    @parent_class = owner_document.create_element('span')
    @parent_class.class_list.add('parent-class')
    @title_container.append_child(@parent_class)
    @title = owner_document.create_element('span')
    @title.class_list.add('interface-name')
    @title_container.append_child(@title)
    @title_container.onclick = method(:on_click_interface)
    append_child(@title_container)

    @content = owner_document.create_element('div')
    @content.class_list.add('interface-content')
    append_child(@content)

    @description = owner_document.create_element('div')
    @description.class_list.add('description')
    @content.append_child(@description)

    @declaration_container = owner_document.create_element('div')
    @declaration_container.class_list.add('declaration')
    @content.append_child(@declaration_container)

    @declaration = owner_document.create_element('code')
    @declaration_container.append_child(@declaration)

    @info = owner_document.create_element('dl')
    @info.class_list.add('info')
    @declaration_container.append_child(@info)

    self.is_header_clickable = true
  end

  def glow
    $window.clear_timeout(@glow_timeout_id) if @glow_timeout_id
    class_list.add('glow')
    class_list.add('transition-short')
    @glow_timeout_id = $window.set_timeout(200) do
      class_list.remove('glow')
      $window.set_timeout(300) { class_list.remove('transition-short') }
    end
  end

  private

  def update_header
    interface_name = interface[:name]
    case interface[:interface_type]
    when :attribute, :method
      interface_name = Documentation.underscore(interface_name)
    end
    @title.inner_text = interface_name

    if interface[:owner]
      @parent_class.inner_text = interface[:owner][:name]
    else
      @parent_class.inner_html = ''
    end
  end

  def update_declaration
    type = interface[:interface_type]
    @declaration.inner_html = ''

    return if type == :class

    # FIXME: Link the attribute types, method return types,
    # and method parameter types to the classes.
    return_type_element = owner_document.create_element('span')
    return_type_element.class_list.add('return-type')
    return_type_element.inner_text = interface[:return_type]
    @declaration.append_child(return_type_element)

    case type 
    when :method
      method_signature = create_method_signature
      @declaration.append_child(method_signature)
    when :attribute 
      name = owner_document.create_element('span')
      name.inner_text = Documentation.underscore(interface[:name])
      @declaration.append_child(name)
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
      name.inner_text = Documentation.underscore(parameter[:name])
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
    @description.inner_html = interface[:description]
  end

  def update_info
    @info.inner_html = ''
    return if interface[:interface_type] != :method

    interface[:parameters].each do |parameter|
      next if parameter[:description].size <= 0

      parameter_name = owner_document.create_element('dt')
      parameter_name_code = owner_document.create_element('code')
      parameter_name_code.inner_text = Documentation.underscore(parameter[:name])
      parameter_name.append_child(parameter_name_code)
      @info.append_child(parameter_name)

      parameter_description = owner_document.create_element('dd')
      parameter_description.inner_html = parameter[:description]
      @info.append_child(parameter_description)
    end

    if interface[:return_type] and interface[:return_type] != 'void' and interface[:return_description].size > 0
      return_name = owner_document.create_element('dt')
      return_name_code = owner_document.create_element('code')
      return_name_code.inner_text = 'return'
      return_name.append_child(return_name_code)
      @info.append_child(return_name)
      
      return_description = owner_document.create_element('dd')
      return_description.inner_html = interface[:return_description]
      @info.append_child(return_description)
    end
  end

  def on_click_interface(event)
    return if !is_header_clickable

    click_interface_event = CustomEvent.new(InterfaceListItem::CLICKED_INTERFACE, {:detail => self})
    dispatch_event(click_interface_event)
  end

end # InterfaceListItemView

end # require