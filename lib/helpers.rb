require 'kronic'

module Sinatra
  module PageTitleHelper
    def page_title(string, opts={})
      @page_title = string
      @page_title_opts ||= { :suffix => true }
      @page_title_opts.merge!(opts)
    end

    def include_page_title
      if @page_title
        title = @page_title
        title << " - Got Gastro" if @page_title_opts[:suffix]
      else
        title = 'Got Gastro'
      end

      "<title>#{title}</title>"
    end
  end

  module RequireJSHelper
    def require_js(filename, opts={})
      @js_filenames ||= {}
      @js_filenames[filename] = opts
    end

    def include_required_js
      if @js_filenames
        @js_filenames.map { |filename, opts|
          type = opts[:type] ? opts[:type] : 'text/javascript'
          %(<script src="#{link_to("/js/#{filename}.js")}" type="#{type}"></script>)
        }.join("\n")
      else
        ""
      end
    end
  end

  module RequireCSSHelper
    def require_css(filename)
      @css_filenames ||= []
      @css_filenames << filename
    end

    def include_required_css
      if @css_filenames
        @css_filenames.map { |filename|
          %(<link href="#{link_to("/css/#{filename}.css")}" rel="stylesheet" type="text/css">)
        }.join("\n")
      else
        ""
      end
    end
  end

  module LinkToHelper
    # from http://gist.github.com/98310
    def link_to(url_fragment, mode=:path_only)
      case mode
      when :path_only
        base = request.script_name
      when :full_url
        if (request.scheme == 'http' && request.port == 80 ||
            request.scheme == 'https' && [80, 443].include?(request.port))
          port = ""
        else
          port = ":#{request.port}"
        end
        base = "#{request.scheme}://#{request.host}#{port}#{request.script_name}"
      else
        raise "Unknown script_url mode #{mode}"
      end
      "#{base}#{url_fragment}"
    end
  end

  module MetaTagHelper
    def meta_tag(attrs={})
      @meta ||= []
      @meta << attrs if attrs[:name] && attrs[:content]
    end

    def include_meta
      if @meta
        @meta.map { |attrs|
          %(<meta name="#{attrs[:name]}" content="#{attrs[:content]}">)
        }.join("\n")
      else
        ""
      end
    end
  end
end
