class Page

  attr_reader :element
  attr_reader :page_name

  def initialize(page_name)
    @page_name = page_name
  end

  def load(&callback)
    url = "#{page_name}_page.html"
    load_html(url) { |success| callback.call(success) }
  end


  protected

  # This function is called when the element for the page is loaded.
  # When this function is called, the @element variable from this class
  # will be filled with the content loaded from the URL.
  def did_load
  end


  private

  # Loads the HTML for a page into the element of this controller.
  # This acts as setting the view for this controller.
  def load_html(url, &callback)
    request = XMLHttpRequest.new
    request.open('GET', url)
    request.response_type = 'document'
    request.onreadystatechange do
      next if request.ready_state != XMLHttpRequest::DONE

      response = request.response
      if !response
        callback.call(false)
        next
      end

      @element = $window.document.create_element('div')
      @element.class_list.add("#{@page_name}-page")
      response.body.children.entries.each { |child| @element.append_child(child) }

      did_load
      callback.call(true)
    end

    request.send()
  end

end