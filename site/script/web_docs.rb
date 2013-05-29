require 'loading_screen.rb',
        'page_stack.rb',
        'url_handler.rb' do

class WebDocs
  attr_reader :page_stack

  def self.instance
    @@instance ||= WebDocs.new
  end

  def initialize
    @page_stack = PageStack.new
  end

  def start
    no_ruby_message = $window.document.query_selector('.no-ruby-message')
    no_ruby_message.parent_node.remove_child(no_ruby_message)

    InterfaceDatabase.instance.load_interfaces do
      did_load_interfaces = true
      
      @page_stack.load do

        $loading_screen.hide
        $loading_screen = nil
        $window.document.body.append_child(@page_stack.element)

        path = $window.location.pathname
        path = path[1..path.length]
        page = URLHandler.page_for_url(path)
        @page_stack.push(page:page, animated:false)
      end
    end
  end

  private

  def self.method_missing(method, *arguments)
    # If we try to call a method on WebDocs that doesn't exist,
    # try to call it on the singleton instance.
    instance.send(method, *arguments)
  end

end # WebDocs

end # require