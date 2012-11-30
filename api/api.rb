module Api
  
  # used in controllers, and in queryable/searchable modules
  module Helpers

    def format_for(params)
      params[:format] || "json"
    end

    def fields_for(models, params)
      return nil if params[:fields] == "all"

      models = [models] unless models.is_a?(Array)

      fields = if params[:fields].blank?
        models.map {|model| model.basic_fields.map {|field| field.to_s}}.flatten
      else
        params[:fields].split ','
      end

      models.each do |model|
        fields << model.cite_key.to_s if model.cite_key
      end

      fields.uniq
    end

    def pagination_for(params)
      default_per_page = 20
      max_per_page = 50
      max_page = 200000000 # let's keep it realistic
      
      # rein in per_page to somewhere between 1 and the max
      per_page = (params[:per_page] || default_per_page).to_i
      per_page = default_per_page if per_page <= 0
      per_page = max_per_page if per_page > max_per_page
      
      # valid page number, please
      page = (params[:page] || 1).to_i
      page = 1 if page <= 0 or page > max_page

      # debug override - if all fields asked for, limit to 1
      per_page = 1 if params[:fields] == "all"
      
      {per_page: per_page, page: page}
    end

    # auto-detect type of argument - allow quotes to force string interpretation
    def value_for(value)
      if ["true", "false"].include? value # boolean
        value == "true"
      elsif value =~ /^\d+$/
        value.to_i
      elsif (value =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/)
        Time.zone.parse(value).utc rescue nil
      else # string
        value.tr "\"", ""
      end
    end

    # special fields used by the system, cannot be used on a model (on the top level)
    def magic_fields
      [
        :fields, :order, 
        :sort, #tokill
        :page, :per_page,
        
        :query, :search,
        :highlight, :highlight_tags, :highlight_size, # tokill

        :citing, # citing.details
        :citation, :citation_details, # tokill

        :explain, :format,

        :apikey, 
        :callback, :_, # jsonp support (_ is to allow cache-busting)
        :captures, :splat # Sinatra routing keywords
      ]
    end
  end

  # installs a few methods when Api::Model is mixed in
  module Model
    module ClassMethods
      def publicly(*types); types.any? ? @publicly = types : @publicly; end
      def basic_fields(*fields); fields.any? ? @basic_fields = fields : @basic_fields; end
      def search_fields(*fields); fields.any? ? @search_fields = fields : @search_fields; end
      def cite_key(key = nil); key ? @cite_key = key : @cite_key; end
    end
    def self.included(base)
      base.extend ClassMethods
      @models ||= []; @models << base
    end
    def self.models; @models; end
  end

  module Routes
    def queryable_route
      queryable = Model.models.select {|model| model.respond_to?(:publicly) and model.publicly.include?(:queryable)}
      @queryable_route ||= /^\/(#{queryable.map {|m| m.to_s.underscore.pluralize}.join "|"})$/
    end

    def searchable_route
      searchable = Model.models.select {|model| model.respond_to?(:publicly) and model.publicly.include?(:searchable)}
      @search_route ||= /^\/search\/((?:(?:#{searchable.map {|m| m.to_s.underscore.pluralize}.join "|"}),?)+)$/
    end
  end
  
end