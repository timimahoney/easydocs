require 'loading_screen.rb',
        'page.rb' do

class PageStack < Page

  def initialize
    super('page-stack')
    @stack = []
  end

  def push(page: nil, animated: true)
    $window.console.log('In push.', page, animated)
    return if !page

    @stack.push(page)

    # FIXME: Show a loading screen when pushing a non-loaded page.
    loading_screen = LoadingScreen.new
    loading_screen.show
    page.load do
      show_page(page)
      loading_screen.hide
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

  def show_page(page)
    @element.append_child(page.element)
  end

end # PageStack

end # require