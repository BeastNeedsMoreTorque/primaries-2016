# Load gems and initialize $logger

require 'rubygems'
require 'bundler/setup'

#Bundler.require(:default)
# Only require the stuff we need, for a bit of speed
require 'archieml'
require 'aws-sdk'
require 'oj'
require 'redcarpet'
require 'ruby-immutable-struct'
require 'hamlit'
require 'sassc'

require_relative './init_airbrake'
require_relative './logger'
