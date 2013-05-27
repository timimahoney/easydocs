def require(*urls, &callback)
  requirer = Requirer.instance
  requirer.require *urls do
    callback.call()
  end
end

class Requirer
  @@instance = nil

  attr_accessor :prefix

  ##
  # Returns a singleton instance of a +Requirer+ for a specified +Window+.
  #
  # [window] the +Window+ of the +Requirer+ you want to return.
  #          If +nil+, then this defaults to the current +Window+.
  def self.instance()
    @@instance = Requirer.new unless @@instance
    @@instance
  end

  def initialize()
    @url_statuses = {}
    @unfinished_requires = []
    @prefix = '/script/'
  end

  ##
  # Loads and runs scripts from URLs.
  # This can be used to include dependencies similar to C++ +#include+.
  #
  # This executes asynchronously. When it completes, the callback will be
  # called. Once the callback has been called, you can safely use the
  # functionality from the included script(s).
  #
  # [*urls] one or more URLs to require.
  # [callback] the code to execute when the require is complete.
  def require(*urls, &callback)
    return if !urls or !urls.size

    if urls_loaded_or_failed?(urls)
      callback.call()
      return
    end

    @unfinished_requires.push({ 
      :callback => callback,
      :urls => urls
    })

    unstarted_urls = urls.select { |url| !@url_statuses[url] }
    unstarted_urls.each do |url|
      @url_statuses[url] = :loading
      script_element = $window.document.create_element('script')
      script_element.type = url[-3, 3] == '.js' ? 'text/javascript' : 'text/ruby'
      script_element.src = "#{prefix}#{url}"
      script_element.async = false
      script_element.onload do
        @url_statuses[url] = :loaded
        check_finished_and_call_callbacks()
      end
      script_element.onerror do
        @url_statuses[url] = :error
        check_finished_and_call_callbacks()
      end
      $window.document.head.append_child(script_element)
    end
  end

  private

  def check_finished_and_call_callbacks
    finished = @unfinished_requires.select { |o| urls_loaded_or_failed?(o[:urls]) }
    @unfinished_requires.delete_if { |o| finished.include? o }
    
    finished.each do |o|
      callback = o[:callback]
      callback.call() if callback
    end
  end

  def urls_loaded_or_failed?(urls)
    return urls.all? do |url| 
      status = @url_statuses[url]
      status == :loaded or status == :error
    end
  end

end