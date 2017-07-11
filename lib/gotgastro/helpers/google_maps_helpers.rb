require 'addressable'

module GotGastro
  module Helpers
    module GoogleMapsHelpers
      class BinarySearch
        include GotGastro::Helpers::GoogleMapsHelpers

        attr_reader :style, :list

        def initialize(style, list)
          @style = style
          @list  = list
        end

        def middle
          @list.length / 2
        end

        def search(max=800)
          m = markers(style, list)

          if m.size > max
            sub = list[0..middle]
            return sub if sub == list
            return BinarySearch.new(style, sub).search
          else
            sub = list[middle..-1]
            return sub if sub == list
            return BinarySearch.new(style, sub).search
          end
        end
      end

      def google_map(opts={})
        options = ActiveSupport::HashWithIndifferentAccess.new({
          'width'       => 400,
          'height'      => 200,
          'marker_size' => 'tiny'
        }).merge(opts)
        location   = opts[:location]
        business   = opts[:business]
        businesses = opts[:businesses]
        zoom       = options[:zoom] || (businesses.size == 0 ? 10 : nil)

        query_params = {
          'scale'       => 2,
          'maptype'     => 'roadmap',
          'size'        => [ options[:width], options[:height] ].join('x'),
          'key'         => options[:api_key],
          'markers'     => [],
        }
        query_params['zoom'] = zoom if zoom

        if location
          style = 'scale:2|icon:http://i.stack.imgur.com/orZ4x.png'
          query_params['markers'] << markers(style, [location])
        end

        if business
          if business.has_major_offences? || business.has_many_problems?
            # critical
            url = 'http://i.imgur.com/tbhV59M.png'
          else
            # warning
            url = 'http://i.imgur.com/fFCz9w7.png'
          end
          style = 'scale:2|icon:' + url

          query_params['markers'] << markers(style, [business])
        end

        if businesses
          warnings = businesses.select {|b| !b.has_many_problems? && !b.has_major_offences? }
          criticals = businesses.select {|b| b.has_major_offences? || b.has_many_problems? }

          case
          when warnings.size > 0 && criticals.size > 0
            style = 'scale:2|icon:http://i.imgur.com/zTluVCr.png'
            max = warnings.index(BinarySearch.new(style, warnings).search(max=900).first)
            query_params['markers'] << markers(style, warnings[0..max])

            style = 'scale:2|icon:http://i.imgur.com/mc6SH33.png'
            max = criticals.index(BinarySearch.new(style, criticals).search(max=900).first)
            query_params['markers'] << markers(style, criticals[0..max])
          when warnings.size > 0
            style = 'scale:2|icon:http://i.imgur.com/zTluVCr.png'
            max = warnings.index(BinarySearch.new(style, warnings).search.first)
            query_params['markers'] << markers(style, warnings[0..max])
          when criticals.size > 0
            style = 'scale:2|icon:http://i.imgur.com/mc6SH33.png'
            max = criticals.index(BinarySearch.new(style, criticals).search.first)
            query_params['markers'] << markers(style, criticals[0..max])
          end
        end

        a = ::Addressable::URI.new(
          :scheme => 'https',
          :host   => 'maps.googleapis.com',
          :path   => '/maps/api/staticmap',
        )

        a.query_values = query_params

        return a.to_s
      end

      def markers(style, collection)
        m = []
        m << style
        collection.each do |item|
          m << [ item.lat, item.lng ].join(',')
        end

        m.join('|')
      end
    end # GoogleMapsHelpers
  end # Helpers
end # GotGastro

