# Represents the message you wish to send. 
# An APN::Notification belongs to an APN::Device.
# 
# Example:
#   apn = APN::Notification.new
#   apn.badge = 5
#   apn.sound = 'my_sound.aiff'
#   apn.alert = 'Hello!'
#   apn.device = APN::Device.find(1)
#   apn.save
# 
# To deliver call the following method:
#   APN::Notification.send_notifications
# 
# As each APN::Notification is sent the <tt>sent_at</tt> column will be timestamped,
# so as to not be sent again.
class APN::Notification < APN::Base
  include ::ActionView::Helpers::TextHelper

  serialize :payload
  
  belongs_to :device, :class_name => 'APN::Device'
  before_save :truncate_alert
  
  # Creates a Hash that will be the payload of an APN.
  # 
  # Example:
  #   apn = APN::Notification.new
  #   apn.badge = 5
  #   apn.sound = 'my_sound.aiff'
  #   apn.alert = 'Hello!'
  #   apn.apple_hash # => {"aps" => {"badge" => 5, "sound" => "my_sound.aiff", "alert" => "Hello!"}}
  def apple_hash
    result = {}
    result['aps'] = {}
    result['aps']['alert'] = self.alert if self.alert
    result['aps']['badge'] = self.badge.to_i if self.badge
    if self.sound
      result['aps']['sound'] = self.sound if self.sound.is_a? String
      result['aps']['sound'] = "1.aiff" if self.sound.is_a?(TrueClass)
    end
    result.merge! payload if payload
    result
  end
  
  # Creates the JSON string required for an APN message.
  # 
  # Example:
  #   apn = APN::Notification.new
  #   apn.badge = 5
  #   apn.sound = 'my_sound.aiff'
  #   apn.alert = 'Hello!'
  #   apn.to_apple_json # => '{"aps":{"badge":5,"sound":"my_sound.aiff","alert":"Hello!"}}'
  def to_apple_json
    self.apple_hash.to_json
  end
  
  # Creates the binary message needed to send to Apple.
  # see http://developer.apple.com/IPhone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
  def message_for_sending
    json = self.to_apple_json
    message = "\0\0 #{self.device.to_hexa}\0#{encode((json.bytesize).chr)}#{encode(json)}"
    raise APN::Errors::ExceededMessageSizeError.new(message) if message.bytesize.to_i > APN::Errors::ExceededMessageSizeError::MAX_BYTES
    message
  end
  def encode(string)
    string.respond_to?(:force_encoding) ? string.force_encoding('BINARY') : string
  end
  
  class << self
    
    # Opens a connection to the Apple APN server and attempts to batch deliver
    # an Array of notifications.
    # This can be run from the following Rake task:
    #   $ rake apn:notifications:deliver
    def send_notifications(notifications)
      sent_ids = []
      sent = false
      message = ''

      notifications.find_each do |noty|
        sent_ids << noty.id
        message << noty.message_for_sending
      end

      return if sent_ids.empty?

      begin
        APN::Connection.open_for_delivery do |conn, sock|
          sent = true
          conn.write(message)
        end
      ensure
        APN::Notification.update_all(['sent_at = ?', Time.now.utc], ['id in (?)', sent_ids]) if sent && sent_ids.any?
      end
    end
    
  end # class << self
  
  private
  # Truncate alert message if message payload will be too long
  def truncate_alert
    return unless self.alert
    while self.alert.length > 1
      begin
        self.message_for_sending
        break
      rescue APN::Errors::ExceededMessageSizeError => e
        self.alert = truncate(self.alert, :escape => false, :length => self.alert.mb_chars.length - 1)
      end
    end
  end
end # APN::Notification
