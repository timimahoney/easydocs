require 'interface_loader.rb' do

class InterfaceDatabase
  @@singleton_instance = nil

  attr_reader :interfaces
  @interfaces = nil

  def self.instance
    @@singleton_instance = InterfaceDatabase.new if !@@singleton_instance
    @@singleton_instance
  end

  def initialize
  end

  def load_interfaces(&callback)
    # FIXME: Save all the loaded interfaces into storage/IndexedDB.
    InterfaceLoader.load_interfaces do |interfaces|
      @interfaces = interfaces
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
    term_lowercase = search_term.downcase
    results_similarities = @interfaces.flat_map do |interface|
      result_similarities = []

      interface_similarity = compare_interface(interface, term_lowercase)
      result_similarities.push([interface_similarity, interface]) if interface_similarity > 0

      attribute_similarities = interface[:attributes].map { |attribute| [compare_attribute(attribute, search_term), attribute] }
      matched_attributes = attribute_similarities.select { |attribute| attribute[0] > 0 }
      result_similarities.concat(matched_attributes)

      method_similarities = interface[:methods].map { |method| [compare_method(method, search_term), method] }
      matched_methods = method_similarities.select { |method| method[0] > 0 }
      result_similarities.concat(matched_methods)
      # result_similarities.map { |element| element[1] }
    end
  
    results_similarities.sort! { |a, b| b[0] <=> a[0] }
    results = results_similarities.map { |o| o[1] }

    $window.console.log("Found #{results.size} results for #{search_term}")

    results
  end

  def compare_interface(interface, search_term)
    compare_string(interface[:name], search_term)
  end

  def compare_attribute(attribute, search_term)
    compare_string(attribute[:name], search_term)
  end

  def compare_method(method, search_term)
    compare_string(method[:name], search_term)
  end

  def compare_string(haystack, needle)
    position = haystack.downcase.index(needle.downcase)
    return 0 if position.nil?
    return 1 if position == 0
    return 0.5 
  end

end # InterfaceDatabase

end # require