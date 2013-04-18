require 'interface_database.rb',
        'interface_list_item_view.rb' do

class SearchController

  attr_reader :element

  def initialize
  end

  def load(&callback)
    load_html('search.html') { |success| callback.call(success) }
  end

  private

  # Loads the HTML for a page into the element of this controller.
  # This acts as setting the view for this controller.
  # FIXME: This should be in the controller superclass.
  def load_html(page_name, &callback)
    # FIXME: Do the actual loading.
    request = XMLHttpRequest.new
    request.open('GET', page_name)
    request.response_type = 'document'
    request.onreadystatechange do 
      next if request.ready_state != XMLHttpRequest::DONE

      response = request.response
      if !response
        callback.call(false)
        next
      end

      @element = $window.document.create_element('div')
      @element.class_list.add("#{page_name}-controller")

      response.body.children.entries.each { |child| @element.append_child(child) }
      did_load
      callback.call(true)
    end

    request.send()
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
    start = Time.now
    timeout_time = 0
    interfaces.each do |interface| 
      $window.set_timeout(timeout_time) { add_interface_to_results(interface) }
      timeout_time += 5
    end
    $window.console.log('Time for adding results: ', Time.now - start)
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