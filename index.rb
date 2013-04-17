require 'search_controller.rb',
        'interface_database.rb' do

console.log('Require finished')

window.add_event_listener('load') do
  console.log('Window loaded');
  $search_controller = SearchController.new

  InterfaceDatabase.instance.load_interfaces do
    console.log('Interfaces were loaded.')
    # FIXME: Don't add the search controller until the interfaces are loaded.
  end




  # FIXME: When we have a generic page controller class,
  # add the SearchController to the document here.
end # onload

end # require