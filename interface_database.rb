require 'interface_loader.rb' do

class InterfaceDatabase
  @@singleton_instance = nil

  attr_reader :interfaces

  def self.instance
    @@singleton_instance = InterfaceDatabase.new if !@@singleton_instance
    @@singleton_instance
  end

  def initialize
    @class_interfaces = nil
    @interfaces = nil
    @cached_searches = {}
  end

  def load_interfaces(&callback)
    # FIXME: Save all the loaded interfaces into storage/IndexedDB.
    InterfaceLoader.load_interfaces do |interfaces|
      @class_interfaces = interfaces
      @interfaces = @class_interfaces.flat_map do |interface|
        results = [interface]
        results.concat(interface[:attributes])
        results.concat(interface[:methods])
        results
      end

      # Do an initial caching of the letters.
      ('a'..'z').each { |letter| find_interfaces(letter) }

      callback.call(@interfaces)
    end
  end

  ##
  # Finds the interfaces in the database for a search term.
  # This will perform a fuzzy search throughout the interface database
  # to find something that matches. It returns a list of hashes.
  # 
  # FIXME: Should this return instances of Interface instead of hashes?
  def find_interfaces(search_term)
    search_term = search_term.downcase

    results = @cached_searches[search_term]
    return results if results

    # We can narrow down the number of interfaces to search through
    # by checking if we have cached results for a partial match of this search term.
    interfaces_to_search = nil
    (0..search_term.length - 2).to_a.reverse.each do |index|
      substring = search_term[0..index]
      interfaces_to_search = @cached_searches[substring]
      break if interfaces_to_search
    end
    interfaces_to_search = @interfaces if !interfaces_to_search

    find_interfaces_internal(search_term, interfaces_to_search)
  end

  private

  def find_interfaces_internal(search_term, all_interfaces)
    term_lowercase = search_term.downcase
    results_similarities = all_interfaces.map do |interface|
      similarity = 0
      case interface[:interface_type]
      when :class
        similarity = compare_class(interface, search_term)
      when :attribute
        similarity = compare_attribute(interface, search_term)
      when :method
        similarity = compare_method(interface, search_term)
      end

      [similarity, interface]
    end
    
    results_similarities = results_similarities.delete_if { |o| o[0] <= 0 }
    results_similarities.sort! { |a, b| b[0] <=> a[0] }
    results = results_similarities.map { |o| o[1] }

    @cached_searches[search_term] = results

    results
  end

  def compare_class(interface, search_term)
    compare_string(interface[:name], search_term)
  end

  def compare_attribute(attribute, search_term)
    attribute_similarity = compare_string(attribute[:name], search_term)
    class_similarity = compare_string(attribute[:owner][:name], search_term)
    attribute_similarity + (class_similarity / 2)
  end

  def compare_method(method, search_term)
    method_similarity = compare_string(method[:name], search_term)
    class_similarity = compare_string(method[:owner][:name], search_term)
    method_similarity + (class_similarity / 2)
  end

  def compare_string(haystack, needle)
    similarity = 0
    needle_fragments = needle.split(/[\.\_ ]/)
    needle_fragments.each do |substring|
      position = haystack.downcase.index(substring.downcase)
      if position
        similarity += 10
      end
    end

    similarity
    # # $window.console.log('needle fragments', needle_fragments)
    # # $window.console.log(needle)
    # position = haystack.downcase.index(needle.downcase)
    # return 0 if position.nil?
    # return 1 if position == 0
    # return 0.5 
  end

end # InterfaceDatabase

end # require