module GotGastro
  module Helpers
    module CSSHelpers
      def require_css(filename)
        @css_filenames ||= []
        @css_filenames << filename
      end

      def include_required_css
        if @css_filenames
          @css_filenames.map { |filename|
            %(<link href="#{link_to("/css/#{filename}.css", :asset => true)}" rel="stylesheet" type="text/css">)
          }.join("\n")
        else
          ""
        end
      end
    end # CSSHelpers
  end # Helpers
end # GotGastro
