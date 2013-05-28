require 'web_docs.rb' do

window.add_event_listener 'load' do
  WebDocs.start
end

# FIXME: Remove these listeners.
window.add_event_listener('unload') { $window.console.log('unload') }
window.add_event_listener('beforeunload') { $window.console.log('beforeunload') }

end # require