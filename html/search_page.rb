require 'interface_database.rb',
        'interface_list_item.rb',
        'class_page.rb',
        'page.rb' do

class SearchPage < Page

  attr_accessor :search_text

  def initialize(url: nil)
    super('search')
    self.search_text = url.split('/')[0] if url
  end

  def location_bar_url
    return "/#{@page_name}" if !search_text || search_text.size == 0
    return "/#{@page_name}/#{search_text}"
  end

  def search_text
    if !@input
      @initial_search_text 
    else
      @input.value
    end
  end

  def search_text=(new_text)
    if !@input
      @initial_search_text = new_text
    else
      @input.value = new_text
      on_search_change(nil)
    end
  end

  private

  def did_load
    @input = @element.query_selector('#search-input')
    @result_list = @element.query_selector('.result-list')
    @header = @element.query_selector('header')

    @input.add_event_listener('keyup', method(:on_search_change))

    if @initial_search_text
      @input.value = @initial_search_text
      on_search_change(nil)
      remove_instance_variable(:@initial_search_text)
    end
  end

  def on_search_change(event)
    @header.class_list.remove('center')

    current_input = @input.value
    $window.console.log("Search changed, input=#{current_input}")

    db = InterfaceDatabase.instance
    interfaces = db.find_interfaces(current_input)
    clear_results()

    @timeout_ids.each { |id| $window.clear_timeout(id) } if @timeout_ids
    @timeout_ids = []
    timeout_time = 0
    interfaces.each do |interface|
      timeout_id = $window.set_timeout(timeout_time) { add_interface_to_results(interface) }
      @timeout_ids.push(timeout_id)
      timeout_time += 5
    end

    WebDocs.page_stack.update_location_bar_url
  end

  def clear_results
    child = @result_list.first_child
    while child
      @result_list.remove_child(child)
      child = @result_list.first_child
    end
  end

  def add_interface_to_results(interface)
    # FIXME: Should we have a class for ResultListItem?
    # FIXME: Cache list item views and reuse them.
    list_item = InterfaceListItem.new
    list_item.interface = interface
    list_item.show_parent_class = true
    @result_list.append_child(list_item)

    list_item.add_event_listener(InterfaceListItem::CLICKED_INTERFACE, method(:on_click_interface))
  end

  def on_click_interface(event)
    interface = event.detail.interface
    class_page = ClassPage.new
    if interface[:interface_type] == :class
      class_page.interface = interface
    else
      class_page.interface = interface[:owner]
      class_page.current_member = interface
    end
    
    WebDocs.page_stack.push(page: class_page, animated: true)
  end

end # SearchPage

end # require