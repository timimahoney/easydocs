require 'loading_screen.rb',
        'page.rb' do

class PageStack < Page

  def initialize
    super('page-stack')
    @stack = []
    @id_to_page = {}
    $window.add_event_listener('popstate', method(:on_pop_state))
  end

  def push(page: nil, animated: true)
    return if !page

    @stack.push(page)
    @id_to_page[page.object_id] = page

    $window.console.log('pushing page: ', page.location_bar_url)

    $window.history.push_state(state_object_for_page(page), nil, page.location_bar_url)

    load_and_show_page(page)
  end

  def update_location_bar_url
    current_state = $window.history.state
    if current_state && current_state.is_a?(Hash) && current_state[:page_stack]
      page = @id_to_page[current_state[:page_id]]
      $window.history.replace_state(state_object_for_page(page), nil, page.location_bar_url)
    end
  end

  protected

  def load_html(&callback)
    element = $window.document.create_element('div')
    element.class_list.add('page-stack')
    callback.call(element)
  end

  def did_load
    $window.console.log('page stack did load')
  end


  private

  def state_object_for_page(page)
    {
      :page_stack => true,
      :page_id => page.object_id,
      :page_url => page.location_bar_url
    }
  end

  def load_and_show_page(page)
    loading_screen = LoadingScreen.new
    loading_screen.show

    page.load do
      loading_screen.hide

      if page.element
        hide_page(@current_page) if @current_page
        @current_page = page
        show_page(@current_page)
      end
    end
  end

  def show_page(page)
    page.will_appear
    @element.append_child(page.element)
    page.did_appear
  end

  def hide_page(page)
    page.will_disappear
    @element.remove_child(page.element)
    page.did_disappear
  end

  def on_pop_state(event)
    $window.console.log('PageStack: on_pop_state:', event.state)
    return if !event.state
    return if !event.state[:page_stack]

    page_to_show = @id_to_page[event.state[:page_id]]
    return if !page_to_show

    hide_page(@current_page) if @current_page
    @current_page = page_to_show
    show_page(@current_page)
  end

end # PageStack

end # require