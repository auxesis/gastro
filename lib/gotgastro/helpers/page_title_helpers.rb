module GotGastro
  module Helpers
    module PageTitleHelpers
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
    end # PageTitleHelper
  end # Helpers
end # GotGastro
