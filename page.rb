class Page

  attr_reader :element
  attr_reader :page_name

  def initialize(page_name)
    @page_name = page_name
  end

  def load(&callback)
    if @element
      callback.call(@element)
      return
    end

    load_html do |element|
      @element = element
      did_load
      callback.call(element)
    end
  end

  def location_bar_url
    "/#{page_name}"
  end

  protected

  # Loads the HTML for the page.
  # When the loading is finished, this calls the callback
  # with the loaded element as the argument.
  # If the argument is nil, then no element was loaded.
  # 
  # By default, the HTML will be loaded from #{page_name}_page.html.
  # Subclasses can override this function to load the HTML manually.
  def load_html(&callback)
    url = "/#{@page_name}_page.html"
    load_html_internal(url) do |element|
      callback.call(element)
    end
  end

  # This function is called when the element for the page is loaded.
  # When this function is called, the @element variable from this class
  # will be filled with the content loaded from the URL.
  def did_load
  end


  private

  def load_html_internal(url, &callback)
    request = XMLHttpRequest.new
    request.open('GET', url)
    request.response_type = 'document'
    request.onreadystatechange do
      next if request.ready_state != XMLHttpRequest::DONE

      response = request.response
      if !response
        callback.call(nil)
        next
      end

      element = $window.document.create_element('div')
      element.class_list.add("#{@page_name}-page")
      response.body.children.entries.each { |child| element.append_child(child) }
      callback.call(element)
    end

    request.send()
  end

end