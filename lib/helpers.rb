require 'dotiw'

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
      binding.pry
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
