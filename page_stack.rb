require 'loading_screen.rb',
        'page.rb' do

class PageStack < Page

  def initialize
    super('page-stack')
    @stack = []
    @id_to_page = {}
    @next_page_id = 0
    $window.add_event_listener('popstate', method(:on_pop_state))
  end

  def push(page: nil, animated: true)
    $window.console.log('In push.', page, animated)
    return if !page

    @stack.push(page)
    page_id = @next_page_id
    @next_page_id += 1
    @id_to_page[page_id] = page
    $window.history.push_state({
      :page_stack => true,
      :page_id => page_id
    }, nil, page.location_bar_url)

    show_page(page)
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

  def show_page(page)
    # FIXME: Show a loading screen when pushing a non-loaded page.
    loading_screen = LoadingScreen.new
    loading_screen.show
    page.load do
      @element.append_child(page.element) if page.element
      loading_screen.hide
    end
  end

  def on_pop_state(event)
    $window.console.log('PageStack: on_pop_state:', $window.history.state, event.state)
    return if !event.state
    return if !event.state[:page_stack]
  end

end # PageStack

end # require