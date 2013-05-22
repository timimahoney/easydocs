require 'interface_database.rb',
        'interface_list_item.rb',
        'page.rb',
        'string_utils.rb' do

class ClassPage < Page

  attr_accessor :interface
  attr_accessor :current_member

  def initialize(url: nil)
    super('class')

    # FIXME: Redirect to search when a class isn't found or if there is no class.
    # Where do we do this? In something like view_did_appear?

    if url
      class_name, member_name = url.split('/')
      if class_name
        self.interface = InterfaceDatabase.find_interface(name: class_name, type: :class)
        self.current_member = find_member(member_name)
      end
    end
  end

  def interface=(new_interface)
    @interface = new_interface

    if @interface
      @methods = @interface[:methods]
      @attributes = @interface[:attributes]
      parent = @interface[:parent]
      while parent
        @methods += parent[:methods]
        @attributes += parent[:attributes]
        parent = parent[:parent]
      end
      @methods.sort_by! { |method| method[:name] }
      @attributes.sort_by! { |attribute| attribute[:name] }
    end

    update_interface_elements if @element
  end

  def current_member=(new_member)
    @current_member = new_member
    WebDocs.page_stack.update_location_bar_url
  end

  def location_bar_url
    return "/#{@page_name}" if !@interface
    return "/#{@page_name}/#{interface[:name]}" if !@current_member
    member_name = Documentation.underscore(@current_member[:name])
    return "/#{@page_name}/#{interface[:name]}/#{member_name}"
  end

  def will_appear
    $window.add_event_listener('popstate', method(:on_pop_state))
  end

  def will_disappear
    $window.remove_event_listener('popstate', method(:on_pop_state))
  end

  protected

  def did_load
    @content_container = @element.query_selector('.content')
    @methods_list = @element.query_selector('.member-list.methods')
    @attributes_list = @element.query_selector('.member-list.attributes')
    @attributes_sidebar_list = @element.query_selector('.sidebar-list.attributes')
    @methods_sidebar_list = @element.query_selector('.sidebar-list.methods')
    @title_element = @element.query_selector('header>h1')
    @interface_description_element = @element.query_selector('.interface-description')
    @interface_list_item = InterfaceListItem.new
    @interface_description_element.append_child(@interface_list_item)

    @content_container.onscroll = method(:on_scroll_content)

    update_interface_elements
    scroll_to_member(@current_member)
  end

  private

  def on_scroll_content(event)
    if !@scrolling_programmatically
      self.current_member = nil
    else
      @scrolling_programmatically = false
    end
  end

  def update_interface_elements
    @attributes_list.inner_html = ''
    @methods_list.inner_html = ''
    @attributes_sidebar_list.inner_html = ''
    @methods_sidebar_list.inner_html = ''
    @title_element.inner_html = ''
    @interface_list_item.interface = nil

    return if !@interface

    @element.query_selector_all('.attributes').each do |attributes_element|
      attributes_element.style.display = @attributes.length == 0 ? 'none' : 'block'
    end

    @title_element.inner_text = @interface[:name]
    @interface_list_item.interface = @interface

    @methods.each { |method| add_member_elements(method, @methods_list, @methods_sidebar_list) }
    @attributes.each { |attribute| add_member_elements(attribute, @attributes_list, @attributes_sidebar_list) }
  end

  def add_member_elements(member, list, sidebar_list)
    list_item = InterfaceListItem.new
    list_item.interface = member
    show_class = member[:owner_id] != @interface[:id]
    list_item.is_header_clickable = show_class
    list_item.show_owner_class = show_class
    list_item.add_event_listener(InterfaceListItem::CLICKED_INTERFACE, method(:on_click_member))
    list.append_child(list_item)

    sidebar_item = $window.document.create_element('li')
    sidebar_item.inner_text = Documentation.underscore(member[:name])
    sidebar_item.class_list.add(member[:interface_type].to_s)
    sidebar_item.class_list.add('ellipsize')
    sidebar_list.append_child(sidebar_item)

    sidebar_item.onclick do
      scroll_to_member(member)
      list_item.glow

      return if self.current_member == member
      self.current_member = member
    end
  end

  def on_click_member(event)
    member = event.detail.interface
    class_page = ClassPage.new
    class_page.interface = member[:owner]
    class_page.current_member = member
    WebDocs.page_stack.push(page: class_page, animated: true)
  end

  def scroll_to_member(member)
    return if !member

    case member[:interface_type]
    when :attribute
      data_array = @attributes
      list = @attributes_list
    when :method
      data_array = @methods
      list = @methods_list
    end

    index = data_array.index(member)
    return if !index

    element = list.child_nodes[index]
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
    @scrolling_programmatically = true
    @content_container.scroll_top = new_scroll_y
  end

  def find_member(member_name)
    return nil if !@attributes || !@methods || !member_name
    lowercase_member_name = Documentation.lower_camel_case(member_name).downcase
    (@attributes + @methods).find { |member| member[:name].downcase == lowercase_member_name }
  end

  def on_pop_state(event)
    $window.console.log("ClassPage on_pop_state", event.state)
    return if event.state[:class_page] != object_id

    $window.console.log("ClassPage on_pop_state for this page.")
    member = find_member(event.state[:member_name])
    scroll_to_member(member)
  end

end # SearchController

end # require