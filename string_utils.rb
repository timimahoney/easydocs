module Documentation

  # FIXME: Just include these in String
  
  def self.underscore(string)
    string.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def self.upper_camel_case(string)
    return string if string !~ /_/ && string =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  def self.lower_camel_case(string)
    string.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
  end
end