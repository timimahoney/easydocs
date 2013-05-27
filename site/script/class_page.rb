require 'interface_database.rb',
        'interface_list_item.rb',
        'page.rb',
        'search_page.rb',
        'string_utils.rb' do

class ClassPage < Page

  attr_accessor :interface
  attr_accessor :current_member

  PLACEMARKER_UPDATE_INTERVAL = 0.1

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

  def self.is_valid_url(url)
    return false if !url

    class_name, _ = url.split('/')
    interface = InterfaceDatabase.find_interface(name: class_name, type: :class)
    return false if !interface

    true
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

    update_current_member_dimming
  end

  def location_bar_url
    return "/#{@page_name}" if !@interface
    return "/#{@page_name}/#{interface[:name]}" if !@current_member
    member_name = Documentation.underscore(@current_member[:name])
    return "/#{@page_name}/#{interface[:name]}/#{member_name}"
  end

  def will_appear
    $window.add_event_listener('popstate', method(:on_pop_state))
    update_current_member_dimming
  end

  def did_appear
    update_placemarker
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
    @interface_list_item.is_header_clickable = false
    @interface_description_element.append_child(@interface_list_item)
    @placemarker = @element.query_selector('.place-marker')
    @sidebar_list_container = @element.query_selector('.sidebar-list-container')

    @content_container.onscroll = method(:on_scroll_content)
    @element.query_selector('.search-button').onclick = method(:on_click_search)

    update_interface_elements
    scroll_to_member(@current_member)
  end

  private

  def update_current_member_dimming
    return if !@attributes_list || !@methods_list
    all_list_items = @attributes_list.child_nodes.entries + @methods_list.child_nodes.entries
    if !@current_member
      all_list_items.each { |item| item.class_list.remove('dim') }
      $window.set_timeout(300) do
        all_list_items.each { |item| item.class_list.remove('transition') }
      end
    else
      member_index = (@attributes + @methods).index(@current_member)      
      all_list_items.each_with_index do |item, index|
        if index == member_index
          item.class_list.remove('dim', 'transition')
        else
          item.class_list.add('dim', 'transition')
        end
      end
    end
  end

  def on_click_search(event)
    search_page = SearchPage.new
    WebDocs.page_stack.push(page: search_page, animated:true)
  end

  def on_scroll_content(event)
    if !@scrolling_programmatically && @current_member
      self.current_member = nil
    end
    @scrolling_programmatically = false

    update_placemarker
  end

  def update_placemarker
    # Don't update the placemarker position too often. Otherwise, it's slow.
    now = Time.now.to_f
    time_since_last_update = now - (@last_placemarker_update || 0)
    return if time_since_last_update < PLACEMARKER_UPDATE_INTERVAL
    @last_placemarker_update = now.to_f

    # Find the top and bottom visible elements, then move the marker to cover those.
    minimum_top = @content_container.scroll_top
    maximum_bottom = @content_container.scroll_top + @content_container.offset_height
    all_children = @attributes_list.child_nodes.entries + @methods_list.child_nodes.entries
    all_sidebar_children = @attributes_sidebar_list.child_nodes.entries + @methods_sidebar_list.child_nodes.entries
    visible = all_children.find_all do |child|
      (child.offset_top + child.offset_height > minimum_top) && (child.offset_top < maximum_bottom)
    end

    first_visible_index = all_children.index(visible.first)
    last_visible_index = all_children.index(visible.last)
    first_sidebar_item = all_sidebar_children[first_visible_index]
    last_sidebar_item = all_sidebar_children[last_visible_index]

    first_sidebar_top = first_sidebar_item.offset_top + 1
    last_sidebar_bottom = last_sidebar_item.offset_top + last_sidebar_item.offset_height - 2
    height = last_sidebar_bottom - first_sidebar_top

    @placemarker.style.top = "#{first_sidebar_top}px"
    @placemarker.style.height = "#{height}px"
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

    @element.query_selector_all('.methods').each do |methods_element|
      methods_element.style.display = @methods.length == 0 ? 'none' : 'block'
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