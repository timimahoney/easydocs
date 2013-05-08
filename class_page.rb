require 'interface_database.rb',
        'interface_list_item.rb',
        'page.rb' do

class ClassPage < Page

  attr_accessor :interface

  def initialize
    super('class')
  end

  def interface=(new_interface)
    @interface = new_interface
    update_interface_elements if @element
  end

  protected

  def did_load
    @content_container = @element.query_selector('.content')
    @member_list = @element.query_selector('.member-list')
    @sidebar_list = @element.query_selector('.member-list-sidebar')
    @title_element = @element.query_selector('header>h1')
    @interface_description_element = @element.query_selector('header .interface-description')

    update_interface_elements
  end

  private

  def update_interface_elements
    @sidebar_list.inner_html = ''
    @member_list.inner_html = ''
    @title_element.inner_html = ''
    @interface_description_element.inner_html = ''

    return if !@interface

    @title_element.inner_text = @interface[:name]

    description_node = @interface[:description].clone_node(true)
    description_node.child_nodes.each { |node| @interface_description_element.append_child(node) }

    all_members = @interface[:methods] + @interface[:attributes]
    all_members.sort_by! { |member| member[:name] }
    all_members.each { |member| add_member_elements(member) }
  end

  def add_member_elements(member)
    list_item = InterfaceListItem.new
    list_item.interface = member
    @member_list.append_child(list_item)

    sidebar_item = $window.document.create_element('li')
    sidebar_item.inner_text = Documentation.underscore(member[:name])
    sidebar_item.class_list.add(member[:interface_type].to_s)
    @sidebar_list.append_child(sidebar_item)

    sidebar_item.onclick do
      item_rect = list_item.get_bounding_client_rect
      target_y = @content_container.scroll_top + item_rect.top + (item_rect.height / 2)
      new_scroll_y = target_y - (@content_container.client_height / 2)
      @content_container.scroll_top = new_scroll_y
      list_item.glow
    end
  end

end # SearchController

end # require