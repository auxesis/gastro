require 'dotiw'
require 'addressable'
require 'active_support/hash_with_indifferent_access'

module Sinatra
  module GoogleMapsHelpers
    class BinarySearch
      include Sinatra::GoogleMapsHelpers

      attr_reader :style, :list

      def initialize(style, list)
        @style = style
        @list  = list
      end

      def middle
        @list.length / 2
      end

      def search
        m = markers(style, list)

        if m.size > 1_600
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
        style = 'icon:http://i.stack.imgur.com/orZ4x.png'
        query_params['markers'] << markers(style, [location])
      end

      if businesses
        warnings = businesses.select {|b| !b.has_major_offences? }
        if warnings.size > 0
          style = "size:#{options[:marker_size]}|color:orange"
          max = warnings.index(BinarySearch.new(style, warnings).search.first)
          query_params['markers'] << markers(style, warnings[0..max])
        end

        criticals = businesses.select {|b| b.has_major_offences? }
        if criticals.size > 0
          style = "size:#{options[:marker_size]}|color:red"
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
  end
end

module Sinatra
  module TimeHelpers
    def distance_of_time_in_words(from_time, to_time = 0, include_seconds_or_options = {}, options = {})
      if include_seconds_or_options.is_a?(Hash)
        options = include_seconds_or_options
      else
        options[:include_seconds] ||= !!include_seconds_or_options
      end
      return distance_of_time(from_time, options) if to_time == 0
      return old_distance_of_time_in_words(from_time, to_time, options) if options.delete(:vague)
      hash = distance_of_time_in_words_hash(from_time, to_time, options)
      display_time_in_words(hash, options)
    end

    def time_ago_in_words(from_time, include_seconds_or_options = {})
      distance_of_time_in_words(from_time, Time.current, include_seconds_or_options)
    end

    def distance_of_time(seconds, options = {})
      options[:include_seconds] ||= true
      display_time_in_words(DOTIW::TimeHash.new(seconds, nil, nil, options).to_hash, options)
    end

    def distance_of_time_in_words_hash(from_time, to_time, options = {})
      from_time = from_time.to_time if !from_time.is_a?(Time) && from_time.respond_to?(:to_time)
      to_time = to_time.to_time if !to_time.is_a?(Time) && to_time.respond_to?(:to_time)

      DOTIW::TimeHash.new(nil, from_time, to_time, options).to_hash
    end

    private

    def display_time_in_words(hash, options = {})
      options.reverse_merge!(
          :include_seconds => false
      ).symbolize_keys!

      include_seconds = options.delete(:include_seconds)
      hash.delete(:seconds) if !include_seconds && hash[:minutes]

      options[:except] = Array.wrap(options[:except]).map!(&:to_sym) if options[:except]
      options[:only] = Array.wrap(options[:only]).map!(&:to_sym) if options[:only]

      # Remove all the values that are nil or excluded. Keep the required ones.
      hash.delete_if do |key, value|
        value.nil? || value.zero? ||
            (options[:except] && options[:except].include?(key)) ||
            (options[:only] && !options[:only].include?(key))
      end

      i18n_scope = options.delete(:scope) || DOTIW::DEFAULT_I18N_SCOPE
      if hash.empty?
        fractions = DOTIW::TimeHash::TIME_FRACTIONS
        fractions = fractions & options[:only] if options[:only]
        fractions = fractions - options[:except] if options[:except]

        I18n.with_options :locale => options[:locale], :scope => i18n_scope do |locale|
          # e.g. try to format 'less than 1 days', fallback to '0 days'
          return locale.translate :less_than_x,
                                  :distance => locale.translate(fractions.first, :count => 1),
                                  :default => locale.translate(fractions.first, :count => 0)
        end
      end

      output = []
      I18n.with_options :locale => options[:locale], :scope => i18n_scope do |locale|
        output = hash.map { |key, value| locale.t(key, :count => value) }
      end

      options.delete(:except)
      options.delete(:only)
      highest_measures = options.delete(:highest_measures)
      highest_measures = 1 if options.delete(:highest_measure_only)
      if highest_measures
        output = output[0...highest_measures]
      end

      options[:words_connector] ||= I18n.translate :'datetime.dotiw.words_connector',
                                                   :default => :'support.array.words_connector',
                                                   :locale => options[:locale]
      options[:two_words_connector] ||= I18n.translate :'datetime.dotiw.two_words_connector',
                                                       :default => :'support.array.two_words_connector',
                                                       :locale => options[:locale]
      options[:last_word_connector] ||= I18n.translate :'datetime.dotiw.last_word_connector',
                                                       :default => :'support.array.last_word_connector',
                                                       :locale => options[:locale]

      output.to_sentence(options)
    end
  end
end

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

  end

  module RequireCSSHelper
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
  end

  module LinkToHelper
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
  end

  module MetaTagHelper
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
  end
end
