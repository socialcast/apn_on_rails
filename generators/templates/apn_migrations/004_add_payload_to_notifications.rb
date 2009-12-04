class AddPayloadToNotifications < ActiveRecord::Migration # :nodoc:
  def self.up
    add_column :apn_notifications, :payload, :text
  end

  def self.down
    remove_column :apn_notifications, :payload, :text
  end
end
