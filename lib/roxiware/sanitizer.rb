require 'uri'

module Roxiware
  module Sanitizer
    BASIC_STYLE_TRANSFORMER = lambda do |env|
	# sanitize style element
	return if env[:node]["style"].blank?
	style_hash = Hash[env[:node]["style"].split(";").collect{|style_element| style_element.split(":")}]
	env[:node]["style"] = style_hash.slice("float", "font", "font-size", "font-weight", "text-decoration", "color", "background", "width", "height").collect{|key, value| [key, value].join(":")}.join(";")
    end

    VIDEO_TRANSFORMER = lambda do |env|
      node      = env[:node]
      node_name = env[:node_name]

      # Don't continue if this node is already whitelisted or is not an element.
      return if env[:is_whitelisted] || !node.element?

      # Don't continue unless the node is an iframe.
      return unless node_name == 'iframe'

      # Verify that the video URL is actually a valid YouTube video URL.
      return unless ((node['src'] =~ /\Ahttps?:\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//) ||
                     (node['src'] =~ /\Ahttp?:\/\/(?:www\.)?youtube(?:-nocookie)?\.com\//) ||
                     (node['src'] =~ /\Ahttp?:\/\/(?:player\.)?vimeo(?:-nocookie)?\.com\//))

      # We're now certain that this is a YouTube embed, but we still need to run
      # it through a special Sanitize step to ensure that no unwanted elements or
      # attributes that don't belong in a YouTube embed can sneak in.
      Sanitize.clean_node!(node, {
	:elements => %w[iframe],

	:attributes => {
	  'iframe'  => %w[allowfullscreen frameborder webkitAllowFullScreen mozallowfullscreen height src width]
	}
      })
      puts "\n\nNODE: #{node}\n\n"
      youtube_uri = URI(node[:src])
      puts "URI #{youtube_uri.inspect}"
      query = Rack::Utils.parse_nested_query(youtube_uri.query || "")
      puts "QUERY #{query.inspect}"
      query["wmode"] = "opaque"
      
      youtube_uri.query = query.to_param
      puts "URI #{youtube_uri.inspect}"
      node[:src] = youtube_uri.to_s
      # Now that we're sure that this is a valid YouTube embed and that there are
      # no unwanted elements or attributes hidden inside it, we can tell Sanitize
      # to whitelist the current node.
      {:node_whitelist => [node]}
    end

    # Sanitizer used for blog posts, etc. which may be produced by 'users' and not admins.
    BASIC_SANITIZER = {
      :elements => %w[
        a abbr b bdo blockquote br caption cite code col colgroup dd del dfn dl
        dt em figcaption figure h1 h2 h3 h4 h5 h6 hgroup i img ins kbd li mark
        ol p pre q rp rt ruby s samp small strike strong sub sup table tbody td
        tfoot th thead time tr u ul var wbr video
      ],

      :attributes => {
        :all         => ['dir', 'lang', 'title', 'style'],
        'a'          => ['href'],
        'blockquote' => ['cite'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'del'        => ['cite', 'datetime'],
        'img'        => ['align', 'alt', 'height', 'src', 'width'],
        'ins'        => ['cite', 'datetime'],
        'ol'         => ['start', 'reversed', 'type'],
        'q'          => ['cite'],
        'table'      => ['summary', 'width'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'],
        'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope', 'width'],
        'time'       => ['datetime', 'pubdate'],
        'ul'         => ['type'],
	'video'      => ['src', 'width', 'height']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'del'        => {'cite' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'ins'        => {'cite' => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]},
        'video'      => {'src' => ['http', 'https', :relative]}
      },
      :transformers => [BASIC_STYLE_TRANSFORMER, VIDEO_TRANSFORMER]
    }

    # sanitizer used for posts by admins, etc.  Includes
    # form elements for contact pages and the like.
    EXTENDED_SANITIZER = {
      :elements => %w[
        a abbr b bdo blockquote br caption cite code col colgroup dd del dfn dl
        dt em figcaption figure h1 h2 h3 h4 h5 h6 hgroup i img ins kbd li mark
        ol p pre q rp rt ruby s samp small strike strong sub sup table tbody td
        tfoot th thead time tr u ul var wbr video form input select option optgroup
        label textarea button fieldset
      ],

      :attributes => {
        :all         => ['dir', 'lang', 'title', 'style'],
        'a'          => ['href', 'target'],
        'blockquote' => ['cite'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'del'        => ['cite', 'datetime'],
        'iframe'     => ['align', 'alt', 'height', 'src', 'width'],
        'img'        => ['align', 'alt', 'height', 'src', 'width'],
        'ins'        => ['cite', 'datetime'],
        'ol'         => ['start', 'reversed', 'type'],
        'q'          => ['cite'],
        'table'      => ['summary', 'width'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width'],
        'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'scope', 'width'],
        'time'       => ['datetime', 'pubdate'],
        'ul'         => ['type'],
	'video'      => ['src', 'width', 'height'],
	'form'       => ['action', 'method', 'enctype', 'name', 'target'],
	'input'      => ['type', 'name', 'value', 'width', 'size', 'checked'],
	'textarea'   => ['name', 'rows', 'cols', 'maxlength'],
	'select'     => ['name', 'multiple', 'size'],
	'option'     => ['value', 'selected'],
	'optgroup'   => ['label'],
	'label'      => ['for'],
	'button'     => ['type'],
	'fieldset'   => ['label']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'del'        => {'cite' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'ins'        => {'cite' => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]},
        'video'      => {'src' => ['http', 'https', :relative]}
      },
      :transformers => [BASIC_STYLE_TRANSFORMER, VIDEO_TRANSFORMER]
    }
  end
end
