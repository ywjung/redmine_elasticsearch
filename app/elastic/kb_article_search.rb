module KbArticleSearch
  extend ActiveSupport::Concern

  module ClassMethods

    def index_mappings
      {
          kb_article: {
              _parent: { type: 'parent_project' },
              _routing: { required: true, path: 'route_key' },
              properties: kb_article_mappings_hash
          }
      }
    end

    def kb_article_mappings_hash
      {
          id: { type: 'integer' },
          project_id: { type: 'integer', index: 'not_analyzed' },
          route_key: { type: 'string', not_analyzed: true },

          # acts_as_event fields
          created_on: { type: 'date', index_name: 'datetime' },
          title: { type: 'string',
                   search_analyzer: 'search_analyzer',
                   index_analyzer: 'index_analyzer' },
          summary: { type: 'string',
                  search_analyzer: 'search_analyzer',
                  index_analyzer: 'index_analyzer' },
          content: { type: 'string',
                  search_analyzer: 'search_analyzer',
                  index_analyzer: 'index_analyzer' },
          author: { type: 'string' },
          url: { type: 'string', index: 'not_analyzed' },
          type: { type: 'string', index: 'not_analyzed' },
          tag: { type: 'string' },
          category: { type: 'string' },

          updated_on: { type: 'date' }
      }.merge(additional_index_mappings).merge(attachments_mappings)
    end

    def allowed_to_search_query(user, options = {})
      options = options.merge(
          permission: :view_kb_articles,
          type: 'kb_article'
      )
      ParentProject.allowed_to_search_query(user, options)
    end

    def searching_scope(project_id)
      self.where('project_id = ?', project_id)
    end
  end
end
