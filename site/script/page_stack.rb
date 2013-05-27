require 'loading_screen.rb',
        'page.rb' do

class PageStack < Page

  @@next_page_id = 0

  PAGE_AFTER_HIDE_STYLE = 'after-hide-position'
  PAGE_BEFORE_SHOW_STYLE = 'before-show-position'

  def initialize
    super('page-stack')
    @stack = []
    @id_to_page = {}
    @page_to_id = {}
    $window.add_event_listener('popstate', method(:on_pop_state))
  end

  def push(page: nil, animated: true)
    return if !page

    @stack.push(page)
    @id_to_page[@@next_page_id] = page
    @page_to_id[page] = @@next_page_id 
    @@next_page_id += 1

    if @stack.size == 1 && !$window.history.state
      $window.history.replace_state(state_object_for_page(page), nil, page.location_bar_url)
    else
      $window.history.push_state(state_object_for_page(page), nil, page.location_bar_url)
    end

    update_page_title

    load_and_show_page(page, animated)
  end

  def update_location_bar_url
    current_state = $window.history.state
    if current_state && current_state.is_a?(Hash) && current_state[:page_stack]
      page = @id_to_page[current_state[:page_id]]
      return if !page
      $window.history.replace_state(state_object_for_page(page), nil, page.location_bar_url)
    end
  end

  def update_page_title
    current_state = $window.history.state
    return if !current_state || !current_state.is_a?(Hash) || !current_state[:page_stack]
    page = @id_to_page[current_state[:page_id]]
    return if !page

    title = $window.document.head.query_selector('title')
    if !title
      title = $window.document.create_element('title')
      $window.document.head.append_child(title)
    end

    title.inner_html = page.page_title
  end

  protected

  def load_html(&callback)
    element = $window.document.create_element('div')
    element.class_list.add('page-stack')
    callback.call(element)
  end

  private

  def state_object_for_page(page)
    {
      :page_stack => true,
      :page_id => @page_to_id[page],
      :page_url => page.location_bar_url
    }
  end

  def load_and_show_page(page, animated)
    loading_screen = LoadingScreen.new
    loading_screen.show

    page.load do
      loading_screen.hide

      if page.element
        hide(page: @current_page, animated: animated) if @current_page
        @current_page = page
        show(page: @current_page, animated: animated)
      end
    end
  end

  def show(page: nil, animated: true, style: 'page-stack-before-show')
    return if !page

    page.will_appear
    page.element.class_list.add('page-stack-transition', 'before-show-transparency', style)
    @element.append_child(page.element)

    $window.set_timeout(0) do 
      page.element.class_list.remove(style, 'before-show-transparency')

      $window.set_timeout(300) do
        page.element.class_list.remove('page-stack-transition')
        page.did_appear
      end
    end    
  end

  def hide(page: nil, style: PAGE_AFTER_HIDE_STYLE, animated: true)
    return if !page

    page.will_disappear

    if animated
      page.element.class_list.add('page-stack-transition', 'after-hide-transparency', style)
      $window.set_timeout(300) do
        @element.remove_child(page.element)
        page.element.class_list.remove('page-stack-transition', 'after-hide-transparency', style)
        page.did_disappear
      end
    else
      @element.remove_child(page.element)
      page.did_disappear
    end
  end

  def on_pop_state(event)
    return if !event.state
    return if !event.state[:page_stack]

    page_to_show = @id_to_page[event.state[:page_id]]
    return if !page_to_show

    page_index = @stack.index(page_to_show)
    previous_index = @stack.index(@current_page) || 0
    going_forward = (page_index > previous_index)
    previous_page_new_style = going_forward ? PAGE_AFTER_HIDE_STYLE : PAGE_BEFORE_SHOW_STYLE
    next_page_new_style = going_forward ? PAGE_BEFORE_SHOW_STYLE : PAGE_AFTER_HIDE_STYLE

    hide(page: @current_page, style: previous_page_new_style)
    @current_page = page_to_show
    show(page: @current_page, style: next_page_new_style)

    update_page_title
  end

end # PageStack

end # require