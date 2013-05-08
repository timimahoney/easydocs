require 'interface_database.rb',
        'interface_list_item.rb',
        'page.rb' do

class SearchPage < Page

  def initialize
    super('search')
  end

  private

  def did_load
    @input = @element.query_selector('#search-input')
    @result_list = @element.query_selector('.result-list')

    @input.add_event_listener('keyup', method(:on_search_change))
  end

  def on_search_change(event)
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
    list_item = InterfaceListItem.new
    list_item.interface = interface
    list_item.show_parent_class = true
    @result_list.append_child(list_item)
  end

end # SearchController

end # require