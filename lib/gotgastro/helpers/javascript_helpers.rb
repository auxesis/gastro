module GotGastro
  module Helpers
    module JavaScriptHelpers
      def require_js(filename, opts={})
        @js_filenames ||= {}
        @js_filenames[filename] = opts
      end

      def include_required_js
        if @js_filenames
          @js_filenames.sort_by {|f,o| f =~ /^vendor/ ? 0 : 1 }.map { |filename, opts|
            type = opts[:type] ? opts[:type] : 'text/javascript'
            # if the path is absolute, insert in directly
            if filename =~ /^http/
              attrs = opts.map{|k,v| %(#{k}="#{v}")}.join(' ')
              %(<script src="#{filename}" type="#{type}" #{attrs}></script>)
            else
              %(<script src="#{link_to("/js/#{filename}.js", :asset => true)}" type="#{type}"></script>)
            end
          }.join("\n")
        else
          ""
        end
      end
    end # JavaScriptHelpers
  end # Helpers
end # GotGastro
