require 'class_page.rb',
        'interface_database.rb',
        'loading_screen.rb',
        'search_page.rb' do


def initialize_application(event)
  loading_screen = LoadingScreen.new
  loading_screen.show
  InterfaceDatabase.instance.load_interfaces do
    show_class_page
    loading_screen.hide
  end 

  # show_search_page
  

  

end

def show_search_page
  loading_screen = LoadingScreen.new
  loading_screen.show

  search_page = SearchPage.new
  search_page.load do
    $window.document.body.insert_before(search_page.element, loading_screen.element)
    loading_screen.hide
  end
end

def show_class_page

  document_results = InterfaceDatabase.instance.find_interfaces('document')
  document = document_results.find { |interface| interface[:name] == 'Document' }

  class_page = ClassPage.new
  class_page.load do
    $window.document.body.append_child(class_page.element)
    class_page.interface = document
  end
end


window.add_event_listener('load', method(:initialize_application)) 

end # require