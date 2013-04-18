class LoadingScreen
  attr_reader :element

  def initialize
    @element = $window.document.create_element('div')
    @element.id = ('loading-screen')
    
    spin_script = $window.document.create_element('script')
    spin_script.type = 'text/javascript'
    spin_script.src = 'spin.min.js'
    $window.document.head.append_child(spin_script)

    spin_script.onload do
      add_spinner_script = $window.document.create_element('script')
      add_spinner_script.type = 'text/javascript'
      script = <<-EOF
  var options = {
    lines: 13, // The number of lines to draw
    length: 20, // The length of each line
    width: 12, // The line thickness
    radius: 30, // The radius of the inner circle
    corners: 1, // Corner roundness (0..1)
    rotate: 90, // The rotation offset
    direction: 1, // 1: clockwise, -1: counterclockwise
    color: '#eee', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 80, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px
  };
  var target = document.getElementById('loading-screen');
  var spinner = new Spinner(options).spin(target);
      EOF
      add_spinner_script.inner_html = script
      $window.document.head.append_child(add_spinner_script);
    end
  end

  def show
    $window.document.body.append_child(@element)
  end

  def hide
    @element.parent_node.remove_child(@element)
  end

end # LoadingScreen