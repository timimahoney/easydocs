require 'interface_database.rb',
        'interface_list_item_view.rb' do

class SearchController

  def initialize

    # FIXME: This should actually do the initialization and loading.
    # Right now, we're hacking it from the main page.
    # We can assume that the page has already been loaded.
    
    load_html('search')
  end

  # Loads the HTML for a page into the element of this controller.
  # This acts as setting the view for this controller.
  # FIXME: This should be in the controller superclass.
  def load_html(page_name)
    # FIXME: Do the actual loading.
    @element = $window.document.get_element_by_id('search-controller')
    did_load
  end

  def did_load
    @input = @element.query_selector('#search-input')
    @result_list = @element.query_selector('#result-list')

    @input.add_event_listener('keyup', method(:on_search_change))
  end

  def on_search_change(event)
    current_input = @input.value
    $window.console.log("Search changed, input=#{current_input}")

    db = InterfaceDatabase.instance
    start = Time.now
    interfaces = db.find_interfaces(current_input)
    $window.console.log('Time for finding interfaces: ', Time.now - start)
    clear_results()
    interfaces.each { |interface| add_interface_to_results(interface) }
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
    list_item = InterfaceListItemView.new
    list_item.interface = interface
    @result_list.append_child(list_item)
  end

end # SearchController

end # require