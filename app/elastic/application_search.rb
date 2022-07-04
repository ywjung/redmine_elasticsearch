module ApplicationSearch
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # document_type name.parameterize
    index_name RedmineElasticsearch::INDEX_NAME
    after_commit :async_update_index
  end

  def to_indexed_json
    RedmineElasticsearch::SerializerService.serialize_to_json(self)
  end

  def async_update_index
    Workers::Indexer.defer(self)
  end

  module ClassMethods

    def type
      document_type || name.parameterize
    end

    def additional_index_mappings
      return {} unless Rails.configuration.respond_to?(:additional_index_properties)
      Rails.configuration.additional_index_properties[self.name.tableize.to_sym] || {}
    end

    def allowed_to_search_query(user, options = {})
      options = options.merge(
        permission: :view_project,
        type:       document_type
      )
      ParentProject.allowed_to_search_query(user, options)
    end

    def searching_scope
      all
    end

    # Import all records to elastic
    # @return [Integer] errors count
    def import(options = {}, &block)
      # Batch size for bulk operations
      batch_size = options.fetch(:batch_size, RedmineElasticsearch::BATCH_SIZE_FOR_IMPORT)

      # Document type
      d_type = options.fetch(:type, type)

      # Imported records counter
      imported = 0

      # Errors counter
      errors = 0

      searching_scope.find_in_batches(batch_size: batch_size || RedmineElasticsearch::BATCH_SIZE_FOR_IMPORT) do |items|
        response = __elasticsearch__.client.bulk(
          index: index_name,
          body:  items.map do |item|
            data   = item.to_indexed_json
            parent = data.delete :_parent
            id = data.delete :id
            data.merge(parent_project_relation: {name: type, parent: parent}, type:  d_type,)
            { index: { _id: id, data: data } }
          end
        )
        imported += items.length
        errors   += response['items'].map { |k, v| k.values.first['error'] }.compact.length

        # Call block with imported records count in batch
        yield(imported) if block_given?
      end
      errors
    end

    def remove_from_index(id)
      __elasticsearch__.client.delete index: index_name, type: document_type, id: "#{type}_#{id}", routing: "#{type}_#{id}"
    end
  end

  def update_index
    relation = self.class.searching_scope.where(id: id)

    if relation.size.zero?
      begin
        self.class.remove_from_index(id)
        return
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        return
      end
    end

    relation.import
  end
end
