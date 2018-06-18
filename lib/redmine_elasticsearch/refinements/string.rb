module RedmineElasticsearch
  module Refinements::String
    ESCAPED_CHARS = %w[\\ /].freeze

    refine ::String do
      def sanitize
        dup.tap(&:sanitize!)
      end

      def sanitize!
        ESCAPED_CHARS.each { |char| gsub!(char, "\\#{char}") }
      end
    end
  end
end
