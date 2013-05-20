module APN
  module Connection
    
    class << self
      
      # Yields up an SSL socket to write notifications to.
      # The connections are close automatically.
      # 
      #  Example:
      #   APN::Configuration.open_for_delivery do |conn|
      #     conn.write('my cool notification')
      #   end
      # 
      # Configuration parameters are:
      # 
      #   APN_CONFIG.passphrase = ''
      #   APN_CONFIG.port = 2195
      #   APN_CONFIG.host = 'gateway.sandbox.push.apple.com' # Development
      #   APN_CONFIG.host = 'gateway.push.apple.com' # Production
      #   APN_CONFIG.cert = File.join(rails_root, 'config', 'apple_push_notification_development.pem')) # Development
      #   APN_CONFIG.cert = File.join(rails_root, 'config', 'apple_push_notification_production.pem')) # Production
      def open_for_delivery(options = {}, &block)
        open(options, &block)
      end
      
      # Yields up an SSL socket to receive feedback from.
      # The connections are close automatically.
      # Configuration parameters are:
      # 
      #   APN_FEEDBACK_CONFIG.passphrase = ''
      #   APN_FEEDBACK_CONFIG.port = 2196
      #   APN_FEEDBACK_CONFIG.host = 'feedback.sandbox.push.apple.com' # Development
      #   APN_FEEDBACK_CONFIG.host = 'feedback.push.apple.com' # Production
      #   APN_FEEDBACK_CONFIG.cert = File.join(rails_root, 'config', 'apple_push_notification_development.pem')) # Development
      #   APN_FEEDBACK_CONFIG.cert = File.join(rails_root, 'config', 'apple_push_notification_production.pem')) # Production
      def open_for_feedback(options = {}, &block)
        options = {:cert => APN_FEEDBACK_CONFIG.cert,
                   :passphrase => APN_FEEDBACK_CONFIG.passphrase,
                   :host => APN_FEEDBACK_CONFIG.host,
                   :port => APN_FEEDBACK_CONFIG.port}.merge(options)
        open(options, &block)
      end
      
      private
      def open(options = {}, &block) # :nodoc:
        options = {:cert => APN_CONFIG.cert,
                   :passphrase => APN_CONFIG.passphrase,
                   :host => APN_CONFIG.host,
                   :port => APN_CONFIG.port}.merge(options)
        cert = File.read(options[:cert])
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.key = OpenSSL::PKey::RSA.new(cert, options[:passphrase])
        ctx.cert = OpenSSL::X509::Certificate.new(cert)
  
        sock = TCPSocket.new(options[:host], options[:port])
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        ssl.sync = true
        ssl.connect
  
        yield ssl, sock if block_given?
  
        ssl.close
        sock.close
      end
      
    end
    
  end # Connection
end # APN
