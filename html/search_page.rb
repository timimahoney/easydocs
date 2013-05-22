require 'interface_database.rb',
        'interface_list_item.rb',
        'class_page.rb',
        'page.rb' do

class SearchPage < Page

  attr_accessor :search_text
  attr_reader :interfaces

  def initialize(url: nil)
    super('search')
    self.search_text = url.split('/')[0] if url
    @interface_list_items = []
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

  def did_appear
    @input.focus
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
    search_string = @input.value
    WebDocs.page_stack.update_location_bar_url
    $window.console.log("Search changed, input=#{search_string}")

    InterfaceDatabase.instance.find_interfaces(search_string) do |interfaces|
      next if search_string != @input.value
      self.interfaces = interfaces
    end
  end

  def interfaces=(new_interfaces)
    @interfaces = new_interfaces

    if !@interfaces
      @interface_list_items.each { |item| item.style.display = 'none' }
      return
    end

    @interfaces.each_with_index do |interface, index|
      item = @interface_list_items[index]
      if !item
        item = InterfaceListItem.new
        item.show_owner_class = true
        @interface_list_items.push(item)
        @result_list.append_child(item)
      end

      item.interface = interface
      item.class_list.remove('display-none')
    end

    items_to_none = @interface_list_items[@interfaces.size..@interface_list_items.size]
    items_to_none.each do |item|
      break if item.class_list.contains('display-none')
      item.class_list.add('display-none')
    end
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