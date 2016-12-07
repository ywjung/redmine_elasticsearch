class ContactSerializer < BaseSerializer
  attributes :project_id,
             :name, :company, :phone,
             :email, :created_on, :updated_on

  def project_id
    object.project.try(:id)
  end

  def _parent
    project_id
  end
end
