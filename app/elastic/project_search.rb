module ProjectSearch
  extend ActiveSupport::Concern

  def async_update_index
    project = ParentProject.find_by(id: id)
    Workers::Indexer.defer(project) if project
    Workers::Indexer.defer(self)
  end

  module ClassMethods

    def allowed_to_search_query(user, options = {})
      options = options.merge(
        permission: :view_project,
        type:       'project'
      )
      ParentProject.allowed_to_search_query(user, options)
    end

  end
end
