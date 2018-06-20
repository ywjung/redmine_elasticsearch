module KbArticleSearch
  extend ActiveSupport::Concern

  module ClassMethods
    def allowed_to_search_query(user, options = {})
      options = options.merge(
          permission: :view_kb_articles,
          type: 'kb_article'
      )

      ParentProject.allowed_to_search_query(user, options)
    end
  end
end
