#!/usr/bin/env ruby
# frozen_string_literal: true

# Derived from PalomarRegistry/PalomarTemplate at
# 128a6c5ce5f48622e69927ccd639cbff401022e8.

require "optparse"
require "yaml"

module FormalizationMetadata
  SENTINEL = /\ATEMPLATE(?::|\z)/
  REQUIRED_LICENSE = "Apache-2.0"
  REQUIRED_SECTIONS = %w[project classification automation review].freeze

  class ValidationError < StandardError; end

  def self.load_document(path)
    text = File.binread(path).force_encoding(Encoding::UTF_8)
    raise ValidationError, "#{path} must be valid UTF-8" unless text.valid_encoding?

    document = YAML.safe_load(
      text,
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    )
    raise ValidationError, "#{path} must contain one top-level mapping" unless document.is_a?(Hash)

    missing = REQUIRED_SECTIONS.reject { |section| document[section].is_a?(Hash) }
    unless missing.empty?
      raise ValidationError,
            "#{path} must contain the required mapping sections: #{missing.join(', ')}"
    end

    document
  rescue Psych::Exception => error
    detail = error.message.lines.first&.strip
    raise ValidationError, "cannot parse #{path} as YAML: #{detail}"
  rescue SystemCallError => error
    raise ValidationError, "cannot read #{path}: #{error.message}"
  end

  def self.placeholder_paths(value, path = "$")
    case value
    when Hash
      value.flat_map do |key, child|
        placeholder_paths(child, "#{path}.#{key}")
      end
    when Array
      value.each_with_index.flat_map do |child, index|
        placeholder_paths(child, "#{path}[#{index}]")
      end
    when String
      value.lstrip.match?(SENTINEL) ? [path] : []
    else
      []
    end
  end

  def self.nonempty_string?(value)
    value.is_a?(String) && !value.strip.empty?
  end

  def self.nonempty_string_list?(value)
    value.is_a?(Array) && !value.empty? && value.all? { |item| nonempty_string?(item) }
  end

  def self.validate(path)
    document = load_document(path)
    unless document["version"] == "v0.4"
      raise ValidationError,
            "#{path} $.version must be \"v0.4\", not #{document['version'].inspect}"
    end

    project = document["project"]
    raise ValidationError, "#{path} $.project.name must be nonempty" unless nonempty_string?(project["name"])

    description = project["description"]
    unless nonempty_string?(description) && description.strip.length <= 10_000
      raise ValidationError,
            "#{path} $.project.description must be nonempty text of at most 10000 characters"
    end

    unless nonempty_string_list?(project["authors"])
      raise ValidationError, "#{path} $.project.authors must be a nonempty list of names"
    end
    unless nonempty_string_list?(project["responsible_maintainers"])
      raise ValidationError,
            "#{path} $.project.responsible_maintainers must be a nonempty list of names"
    end
    unless project["license"] == REQUIRED_LICENSE
      raise ValidationError,
            "#{path} $.project.license must be #{REQUIRED_LICENSE.inspect}"
    end

    classification = document["classification"]
    unless nonempty_string_list?(classification["arxiv"]) && classification["arxiv"].length.between?(1, 2)
      raise ValidationError, "#{path} $.classification.arxiv must contain one or two codes"
    end
    unless nonempty_string_list?(classification["msc2020"]) && classification["msc2020"].length.between?(1, 8)
      raise ValidationError, "#{path} $.classification.msc2020 must contain one to eight codes"
    end

    sources = document["sources"]
    unless sources.is_a?(Array) && !sources.empty? && sources.all? { |item| item.is_a?(Hash) }
      raise ValidationError, "#{path} $.sources must be a nonempty list of mappings"
    end
    sources.each_with_index do |source, index|
      unless nonempty_string?(source["title"]) && nonempty_string?(source["relationship"])
        raise ValidationError,
              "#{path} $.sources[#{index}] needs nonempty title and relationship"
      end
    end

    methods = document.dig("automation", "methods")
    unless methods.is_a?(Array) && !methods.empty? &&
           methods.all? { |method| method.is_a?(Hash) && nonempty_string?(method["method"]) }
      raise ValidationError,
            "#{path} $.automation.methods must be a nonempty list with a method in every entry"
    end
    unless nonempty_string?(document.dig("review", "status"))
      raise ValidationError, "#{path} $.review.status must be nonempty"
    end

    placeholders = placeholder_paths(document)
    return if placeholders.empty?

    locations = placeholders.map { |item| "  #{item}" }.join("\n")
    raise ValidationError, <<~MESSAGE.chomp
      #{path} still contains #{placeholders.length} TEMPLATE value(s):
      #{locations}
    MESSAGE
  end

  def self.run_cli(arguments, output: $stdout, errors: $stderr)
    parser = OptionParser.new do |options|
      options.banner = "Usage: #{File.basename($PROGRAM_NAME)} [formalization.yaml]"
    end
    remaining = parser.parse(arguments)
    raise OptionParser::InvalidArgument, "expected at most one metadata path" if remaining.length > 1

    path = remaining.fetch(0, "formalization.yaml")
    validate(path)
    output.puts "#{path} passes the repository metadata checks"
    0
  rescue OptionParser::ParseError => error
    errors.puts error.message
    errors.puts parser
    2
  rescue ValidationError => error
    errors.puts error.message
    1
  end
end

exit FormalizationMetadata.run_cli(ARGV) if $PROGRAM_NAME == __FILE__
