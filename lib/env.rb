# Load gems and initialize $logger

require 'rubygems'
require 'bundler/setup'

# Before we load sprockets.rb, which is slow, monkey-patch its dependency
# https://github.com/rails/sprockets/issues/17
begin
  require 'sprockets/mime'
  module Sprockets::Mime
    alias_method(:original_register_mime_type, :register_mime_type)

    def register_mime_type(mime_type, extensions: [], charset: nil)
      if mime_type == 'application/javascript' || mime_type == 'text/css'
        original_register_mime_type(mime_type, extensions: extensions, charset: charset)
      end
    end
  end
rescue LoadError
  # Doesn't work on production. BOO. Oh well, no harm done.
end

Bundler.require(:default)

require_relative './logger'
