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
  extend ::ActionView::Helpers::TextHelper

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
  def message_for_sending
    json = self.to_apple_json
    message = "\0\0 #{self.device.to_hexa}\0#{(json.length > 255 ? 255 : json.length).chr}#{json}"
    raise APN::Errors::ExceededMessageSizeError.new(message) if message.size.to_i > 256
    message
  end
  
  class << self
    
    # Opens a connection to the Apple APN server and attempts to batch deliver
    # an Array of notifications.
    # 
    # This method expects an Array of APN::Notifications. If no parameter is passed
    # in then it will use the following:
    #   APN::Notification.all(:conditions => {:sent_at => nil})
    # 
    # As each APN::Notification is sent the <tt>sent_at</tt> column will be timestamped,
    # so as to not be sent again.
    # 
    # This can be run from the following Rake task:
    #   $ rake apn:notifications:deliver
    def send_notifications(notifications = APN::Notification.all(:conditions => {:sent_at => nil}))
      unless notifications.nil? || notifications.empty?

        APN::Connection.open_for_delivery do |conn, sock|
          notifications.each do |noty|
            conn.write(noty.message_for_sending)
            noty.sent_at = Time.now
            noty.save
          end
        end

      end
    end
    
  end # class << self
  
  private
  # Truncate alert message if message payload will be too long
  def truncate_alert
    return unless self.alert
    begin
      self.message_for_sending
    rescue APN::Errors::ExceededMessageSizeError => e
      self.alert = truncate(self.alert, :length => self.alert.size - e.overage)
    end
  end
end # APN::Notification