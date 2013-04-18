require 'search_controller.rb',
        'interface_database.rb',
        'loading_screen.rb' do

console.log('Require finished')

window.add_event_listener('load') do
  $window.console.log('showing loading screen')
  loading_screen = LoadingScreen.new
  loading_screen.show
  still_loading = [:search, :database];

  $search_controller = SearchController.new
  $search_controller.load do
    $window.console.log('Search was loaded.')
    still_loading.delete(:search)
    $window.document.body.insert_before($search_controller.element, loading_screen.element)
    loading_screen.hide if still_loading.size == 0
  end

  InterfaceDatabase.instance.load_interfaces do
    console.log('Interfaces were loaded.')
    still_loading.delete(:database)
    loading_screen.hide if still_loading.size == 0
  end 

end # onload

end # require