class AttachmentSerializer < ActiveModel::Serializer
  self.root = false

  # todo: move max_size and supported_mime_patterns and unsupported phrase to plugin configuration

  MAX_SIZE  = 5.megabytes

  SUPPORTED_EXTENSIONS = %w{
    .doc .docx .htm .html .json .ods .odt .pdf .ppt .pptx .rb .rtf .sh .sql .txt .xls .xlsx .xml .yaml .yml
  }

  SUPPORTED_MIME_PATTERNS = %w{
    application\/json
    application\/msword
    application\/pdf
    application\/vnd.ms-excel
    application\/vnd.ms-powerpoint
    application\/vnd.ms-publisher
    application\/vnd.oasis.opendocument.spreadsheet
    application\/vnd.oasis.opendocument.text
    application\/vnd.openxmlformats-officedocument
    application\/vnd.openxmlformats-officedocument
    application\/vnd.openxmlformats-officedocument
    application\/x-javascript
    application\/x-ruby
    application\/x-sh
    application\/x-shellscript
    application\/x-yaml
    application\/xml
    message\/rfc822
    text\/
  }

  UNSUPPORTED = 'unsupported'

  attributes :created_on,
    :filename,
    :description,
    :author,
    :filesize,
    :digest,
    :downloads,
    :author_id,
    :content_type,
    :file

  def author
    object.author && object.author.to_s
  end

  def file
    content = supported? ? File.read(object.diskfile) : UNSUPPORTED
    Base64.strict_encode64(content)
  end

  private

  def supported?
    object.filesize > 0 &&
      object.filesize < MAX_SIZE &&
      (extension_supported? || content_type_supported?) &&
      object.readable?
  end

  def extension_supported?
    SUPPORTED_EXTENSIONS.include?($1) if object.filename =~ /(\.[^\.]+)$/
  end

  def content_type_supported?
    SUPPORTED_MIME_PATTERNS.any? { |pattern| object.content_type =~ Regexp.new(pattern, true) }
  end
end
