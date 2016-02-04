# Like the official Sprockets lib/sprockets.rb, but with fewer features.
#
# Loads significantly faster.

require 'sprockets/version'
require 'sprockets/cache'
require 'sprockets/environment'
require 'sprockets/errors'

module Sprockets
  # Extend Sprockets module to provide global registry
  #require 'sprockets/configuration'
  require 'sprockets/context'
  extend Configuration

  self.config = {
    bundle_processors: Hash.new { |h, k| [].freeze }.freeze,
    bundle_reducers: Hash.new { |h, k| {}.freeze }.freeze,
    compressors: Hash.new { |h, k| {}.freeze }.freeze,
    dependencies: Set.new.freeze,
    dependency_resolvers: {}.freeze,
    digest_class: Digest::MD5, # faster? Maybe unused....
    engine_mime_types: {}.freeze,
    engines: {}.freeze,
    mime_exts: {}.freeze,
    mime_types: {}.freeze,
    paths: [].freeze,
    pipelines: {}.freeze,
    postprocessors: Hash.new { |h, k| [].freeze }.freeze,
    preprocessors: Hash.new { |h, k| [].freeze }.freeze,
    registered_transformers: Hash.new { |h, k| {}.freeze }.freeze,
    root: File.expand_path('..', __FILE__).freeze,
    transformers: Hash.new { |h, k| {}.freeze }.freeze,
    version: "",
    gzip_enabled: true
  }.freeze
  self.computed_config = {}

  @context_class = Context

  require 'logger'
  @logger = Logger.new($stderr)
  @logger.level = Logger::FATAL

  # Common asset text types
  register_mime_type 'application/javascript', extensions: ['.js'], charset: :unicode

  register_pipeline :self do |env, type, file_type, engine_extnames|
    env.self_processors_for(type, file_type, engine_extnames)
  end

  register_pipeline :default do |env, type, file_type, engine_extnames|
    env.default_processors_for(type, file_type, engine_extnames)
  end

  require 'sprockets/directive_processor'
  register_preprocessor 'application/javascript', DirectiveProcessor.new(comments: ["//"])

  require 'sprockets/bundle'
  register_bundle_processor 'application/javascript', Bundle

  register_bundle_metadata_reducer 'application/javascript', :data, proc { "" }, Utils.method(:concat_javascript_sources)

  register_dependency_resolver 'environment-version' do |env|
    env.version
  end
  register_dependency_resolver 'environment-paths' do |env|
    env.paths.map {|path| env.compress_from_root(path) }
  end
  register_dependency_resolver 'file-digest' do |env, str|
    env.file_digest(env.parse_file_digest_uri(str))
  end
  register_dependency_resolver 'processors' do |env, str|
    env.resolve_processors_cache_key_uri(str)
  end

  #depend_on 'environment-version'
  #depend_on 'environment-paths'
end
