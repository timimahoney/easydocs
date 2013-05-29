class LoadingScreen
  attr_reader :element

  def initialize
    @element = $window.document.create_element('div')
    @element.class_list.add('loading-screen', 'hidden', 'transition')
    @element.id = "loading_screen#{(Time.now.to_f * 1000).to_i}"

    container = $window.document.create_element('div')
    container.class_list.add('loading-container')
    @element.append_child(container)

    text = $window.document.create_element('p')
    text.inner_text = 'Loading data...'
    container.append_child(text)

    bar = $window.document.create_element('div')
    bar.class_list.add('loading-bar')
    container.append_child(bar)
  end

  def show
    @can_hide_at = Time.now + 0.25
    $window.set_timeout(0) { @element.class_list.remove('hidden') }
  end

  def hide
    return if @element.class_list.contains('hidden')

    time_left_until_hide = @can_hide_at - Time.now
    if time_left_until_hide.to_f > 0
      new_time_left = time_left_until_hide * 1000
      $window.set_timeout(new_time_left) { hide } 
      return
    end

    @element.class_list.add('hidden')
    $window.set_timeout(250) { @element.parent_node.remove_child(@element) }
  end

end # LoadingScreen