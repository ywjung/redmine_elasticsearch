class BaseSerializer < ActiveModel::Serializer
  self.root = false

  attributes :_parent, :datetime, :title, :description, :author, :url, :type, :redmine_id, :id

  def _parent
    project_id if respond_to? :project_id
  end

  def id
    if is_a?(Project)
      object.id
    else
      "#{type}_#{object.id}"
    end
  end

  def redmine_id
    id
  end

  %w(datetime title description).each do |attr|
    class_eval "def #{attr}() object.event_#{attr} end"
  end

  def type
    object.class.type
  end

  def author
    object.event_author && object.event_author.to_s
  end

  def url
    url_for object.event_url(default_url_options)
  rescue
    nil
  end

  def default_url_options
    { host: Setting.host_name, protocol: Setting.protocol }
  end
end
