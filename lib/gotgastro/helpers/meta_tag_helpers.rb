module GotGastro
  module Helpers
    module MetaTagHelpers
      def meta_tag(attrs={})
        @meta ||= []
        @meta << attrs if (attrs[:name] || attrs[:property]) && attrs[:content]
      end

      def include_meta
        if @meta
          @meta.map { |attrs|
            field = attrs.keys.include?(:name) ? :name : :property
            %(<meta #{field}="#{attrs[field]}" content="#{attrs[:content]}">)
          }.join("\n")
        else
          ""
        end
      end
    end # MetaTagHelpers
  end # Helpers
end # GotGastro
