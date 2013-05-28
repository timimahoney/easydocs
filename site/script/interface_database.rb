require 'interface_loader.rb' do

class InterfaceDatabase
  @@singleton_instance = nil

  LIMIT = 25

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

      callback.call(@interfaces) if callback
    end
  end

  def find_interfaces(search_term, &callback)
    search_term = search_term.downcase

    results = @cached_searches[search_term]
    if results
      callback.call(results.take(LIMIT))
      return
    end

    # We can narrow down the number of interfaces to search through
    # by checking if we have cached results for a partial match of this search term.
    interfaces_to_search = nil
    (0..search_term.length - 2).to_a.reverse.each do |index|
      substring = search_term[0..index]
      interfaces_to_search = @cached_searches[substring]
      break if interfaces_to_search
    end
    interfaces_to_search = @interfaces if !interfaces_to_search

    found_interfaces = find_interfaces_internal(search_term, interfaces_to_search)
    @cached_searches[search_term] = found_interfaces
    callback.call(found_interfaces.take(LIMIT))
  end

  def find_interface(name: nil, type: nil)
    return nil if !name

    found_interface = @interfaces.find do |interface| 
      interface[:name] == name && (!type || interface[:interface_type] == type)
    end

    found_interface
  end

  private

  def find_interfaces_internal(search_term, all_interfaces)
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

    results
  end

  def compare_class(interface, search_term)
    compare_string(interface[:name], search_term)
  end

  def compare_attribute(attribute, search_term)
    attribute_similarity = compare_string(attribute[:name], search_term)
    class_similarity = compare_string(attribute[:owner][:name], search_term)
    attribute_similarity + (class_similarity / 4)
  end

  def compare_method(method, search_term)
    method_similarity = compare_string(method[:name], search_term)
    class_similarity = compare_string(method[:owner][:name], search_term)
    method_similarity + (class_similarity / 4)
  end

  def compare_string(haystack, needle)
    similarity = 0
    needle_fragments = needle.split(/[\.\_ ]/)
    haystack_downcase = haystack.downcase
    needle_fragments.each do |substring|
      substring_downcase = substring.downcase
      if haystack_downcase == substring_downcase
        similarity += 15
        next
      end

      position = haystack_downcase.index(substring_downcase)
      if position == 0
        similarity += 10
      elsif position
        similarity += 5
      end
    end

    similarity
  end

  def self.method_missing(method, *arguments)
    # Try to call a method on the singleton instance.
    instance.send(method, *arguments)
  end

end # InterfaceDatabase

end # require