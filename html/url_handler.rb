require 'class_page.rb',
        'search_page.rb' do

class URLHandler

  def self.page_for_url(url)
    split_path = url.split('/')
    top_level_path = split_path[0]
    remaining_url = split_path.drop(1).join('/')
    case top_level_path
    when 'search'
      SearchPage.new(url: remaining_url)
    when 'class'
      ClassPage.new(url: remaining_url)
    else
      SearchPage.new
    end
  end

end # URLHandler

end # require