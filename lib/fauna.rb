require 'json'
require 'logger'
require 'uri'
require 'faraday'
require 'cgi'
require 'zlib'

load "#{File.dirname(__FILE__)}/tasks/fauna.rake" if defined?(Rake)

require 'fauna/util'
require 'fauna/connection'
require 'fauna/client'
