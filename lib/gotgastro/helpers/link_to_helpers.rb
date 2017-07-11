module GotGastro
  module Helpers
    module LinkToHelpers
      # from http://gist.github.com/98310
      def link_to(url_fragment, opts={})
        options = { :mode => :path_only }.merge(opts)
        case
          # if thing being linked to is an asset, and CDN is configured, link to CDN
        when opts[:asset] && cdn?
          base = config['settings']['cdn_base']
        when options[:mode] == :path_only
          base = request.script_name
        when options[:mode] == :full_url
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

      def nav_query(attrs)
        a = ::Addressable::URI.new
        a.query_values = attrs
        a.query
      end
    end # LinkToHelpers
  end # Helpers
end # GotGastro
