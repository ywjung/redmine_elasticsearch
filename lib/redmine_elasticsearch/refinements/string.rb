module RedmineElasticsearch
  module Refinements::String
    ESCAPED_CHARS = %w[\\ /].freeze

    refine ::String do
      def sanitize
        dup.tap { |s| ESCAPED_CHARS.each { |char| s.gsub!(char, "\\#{char}") } }
      end
    end
  end
end
