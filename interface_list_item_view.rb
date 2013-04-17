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
    @description = owner_document.create_element('div')
    append_child(@title)
    append_child(@description)
  end

  def interface=(interface)
    @interface = interface

    class_list.remove('class', 'method', 'attribute')
    class_list.add(interface[:interface_type].to_s)

    
    case interface[:interface_type]
    when :method, :attribute
      @title.inner_text = Documentation.underscore(interface[:name])
      owner = interface[:owner]
      owner_text = owner_document.create_element('span')
      owner_text.class_list.add('owner')
      owner_string = prettify_owner(owner[:name])
      owner_text.inner_text = owner_string + '.'
      @title.insert_before(owner_text, @title.first_child)
    else
      @title.inner_text = interface[:name]
    end

    update_description(interface[:description])
  end

  def update_description(new_description)
    child = @description.first_child
    while child
      @description.remove_child(child)
      child = @description.first_child
    end

    if (interface[:description])
      description_node = new_description.clone_node(true)
      description_node.child_nodes.each { |node| @description.append_child(node) }
    end
  end

  def prettify_owner(owner_name)
    owner_name = Documentation.underscore(owner_name)
    owner_name.sub(/html_(.+)_element/, '\1')
  end

end # InterfaceListItemView

end # require