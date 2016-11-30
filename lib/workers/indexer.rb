module Workers
  class Indexer

    class IndexError < StandardError
    end

    include Sidekiq::Worker
    sidekiq_options :queue => :index_queue, :retry => 2, :backtrace => true

    def perform(options)
      id, type = options.with_indifferent_access[:id], options.with_indifferent_access[:type]
      id.nil? ? update_class_index(type) : update_instance_index(type, id)
    end

    def update_class_index(type)
      klass = RedmineElasticsearch.type2class(type)
      klass.update_index
    rescue ::RestClient::Exception, Errno::ECONNREFUSED => e
      raise IndexError, e, e.backtrace
    end

    def update_instance_index(type, id)
      klass = RedmineElasticsearch.type2class(type)
      document = klass.find id
      if document.respond_to?(:not_index) and document.not_index
        klass.index.remove type, id
        klass.index.refresh
      else
        document.update_index
      end
    rescue ActiveRecord::RecordNotFound
      klass.index.remove type, id
      klass.index.refresh
    rescue ::RestClient::Exception, Errno::ECONNREFUSED => e
      raise IndexError, e, e.backtrace
    end

    class << self
      def defer(object_or_class)
        if object_or_class.is_a? Class
          params = { type: object_or_class.index_document_type }
          self.perform_async(params)
        elsif object_or_class.id?
          params = {
              id: object_or_class.id,
              type: object_or_class.class.index_document_type
          }
          self.perform_async(params)
        end
      rescue Exception => e
        Rails.logger.debug "INDEXER: #{e.class} => #{e.message}"
        raise
      end

      def perform_async(options)
        Sidekiq::Client.enqueue(Workers::Indexer, options)
      end
    end
  end
end
