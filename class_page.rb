require 'interface_database.rb',
        'interface_list_item.rb',
        'page.rb',
        'string_utils.rb' do

class ClassPage < Page

  attr_accessor :interface

  def initialize(url: nil)
    super('class')

    # FIXME: Redirect to search when a class isn't found or if there is no class.
    # Where do we do this? In something like view_did_appear?

    if url
      class_name, member_name = url.split('/')
      if class_name
        self.interface = InterfaceDatabase.find_interface(name: class_name, type: :class)
        @current_member = find_member(member_name)
      end
    end
  end

  def interface=(new_interface)
    @interface = new_interface

    if @interface
      @members = @interface[:methods] + @interface[:attributes]
      @members.sort_by! { |member| member[:name] }
    end

    update_interface_elements if @element
  end

  def location_bar_url
    return "/#{@page_name}" if !@interface
    return "/#{@page_name}/#{interface[:name]}" if !@current_member
    member_name = Documentation.underscore(@current_member[:name])
    return "/#{@page_name}/#{interface[:name]}/#{member_name}"
  end

  protected

  def did_load
    @content_container = @element.query_selector('.content')
    @member_list = @element.query_selector('.member-list')
    @sidebar_list = @element.query_selector('.member-list-sidebar')
    @title_element = @element.query_selector('header>h1')
    @interface_description_element = @element.query_selector('header .interface-description')

    update_interface_elements
    scroll_to_member(@current_member)
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

    @members.each { |member| add_member_elements(member) }
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
      scroll_to_member(member)
      list_item.glow

      return if @current_member == member
      @current_member = member
      update_location_bar_url
    end
  end

  def scroll_to_member(member)
    member_index = @members.index(member)
    return if !member_index
    element = @member_list.child_nodes[member_index]
    return if !element
    center_element_on_page(element)
  end

  def center_element_on_page(element)
    item_rect = element.get_bounding_client_rect

    # Wait until the page is loaded
    if (item_rect.width == 0 || item_rect.height == 0)
      $window.set_timeout(0) { center_element_on_page(element) }
      return
    end

    target_y = @content_container.scroll_top + item_rect.top + (item_rect.height / 2)
    new_scroll_y = target_y - (@content_container.client_height / 2)
    @content_container.scroll_top = new_scroll_y
  end

  def find_member(member_name)
    return nil if !@members || !member_name
    lowercase_member_name = Documentation.lower_camel_case(member_name).downcase
    @members.find { |member| member[:name].downcase == lowercase_member_name }
  end

  def update_location_bar_url
    $window.history.push_state({ :class_page => true }, nil, location_bar_url)
  end

end # SearchController

end # require