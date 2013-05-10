require 'loading_screen.rb',
        'page_stack.rb',
        'search_page.rb' do

class WebDocs
  attr_reader :page_stack

  def self.instance
    @@instance ||= WebDocs.new
  end

  def initialize
    @page_stack = PageStack.new
  end

  def start
    @page_stack.load do
      $window.document.body.append_child(@page_stack.element)
      search_page = SearchPage.new
      @page_stack.push(page:search_page, animated:false)
      InterfaceDatabase.instance.load_interfaces
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