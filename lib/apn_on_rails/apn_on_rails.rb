require 'socket'
require 'openssl'

rails_root = File.join(FileUtils.pwd, 'rails_root')
if defined?(RAILS_ROOT)
  rails_root = RAILS_ROOT
end

rails_env = 'development'
if defined?(RAILS_ENV)
  rails_env = RAILS_ENV
end

module APN
  class Config
    def initialize
      @config_hash ||= {}
      @defaults_hash = {}
    end

    def set_default(key, value)
      @defaults_hash[key] = value
    end

    def set(key, value)
      @config_hash[key] = value
    end

    def method_missing(m, *args, &block)
      key = m.to_sym
      if @config_hash.has_key? key
        return @config_hash[key]
      elsif @defaults_hash.has_key? key
        return @defaults_hash[key]
      else
        return nil
      end
    end

  end
end
APN_CONFIG = APN::Config.new
APN_CONFIG.set_default(:passphrase, '')
APN_CONFIG.set_default(:port, 2195)

APN_FEEDBACK_CONFIG = APN::Config.new
APN_FEEDBACK_CONFIG.set_default(:passphrase, APN_CONFIG.passphrase)
APN_FEEDBACK_CONFIG.set_default(:port, 2196)

if rails_env == 'production'
  APN_CONFIG.set_default(:host, 'gateway.push.apple.com')
  APN_CONFIG.set_default(:cert, File.join(rails_root, 'config', 'apple_push_notification_production.pem'))

  APN_FEEDBACK_CONFIG.set_default(:host, 'feedback.push.apple.com')
  APN_FEEDBACK_CONFIG.set_default(:cert, APN_CONFIG.cert)
else
  APN_CONFIG.set_default(:host, 'gateway.sandbox.push.apple.com')
  APN_CONFIG.set_default(:cert, File.join(rails_root, 'config', 'apple_push_notification_development.pem'))

  APN_FEEDBACK_CONFIG.set_default(:host, 'feedback.sandbox.push.apple.com')
  APN_FEEDBACK_CONFIG.set_default(:cert, APN_CONFIG.cert)
end

module APN # :nodoc:
  
  module Errors # :nodoc:
    
    # Raised when a notification message to Apple is longer than 256 bytes.
    class ExceededMessageSizeError < StandardError
      MAX_BYTES = 256
      def initialize(message) # :nodoc:
        super("The maximum size allowed for a notification payload is #{MAX_BYTES} bytes: '#{message}'")
      end
    end
    
  end # Errors
  
end # APN

Dir.glob(File.join(File.dirname(__FILE__), 'app', 'models', 'apn', '*.rb')).sort.each do |f|
  require f
end

%w{ models controllers helpers }.each do |dir| 
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path 
  if ActiveSupport::Dependencies.respond_to?(:autoload_paths)
    ActiveSupport::Dependencies.autoload_paths << path 
    ActiveSupport::Dependencies.autoload_once_paths.delete(path) 
  else
    ActiveSupport::Dependencies.load_paths << path 
    ActiveSupport::Dependencies.load_once_paths.delete(path)
  end
end
