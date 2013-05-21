# encoding: UTF-8
require 'spec_helper'

describe APN::Notification do

  describe 'truncate_alert' do

    it 'should truncate alert text to fit within 256 byte total message size limit' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create.id, :sound => true, :badge => nil, :alert => 'a' * 250)
      noty.save!
      noty.alert.should start_with 'aaa'
      noty.alert.should end_with 'aaa...'
      noty.message_for_sending.bytesize.should == 256
    end

    it 'should truncate very long unicode alert text to fit within 256 byte total message size limit' do
      s = "Ω" * 250
      noty = NotificationFactory.new(:device_id => DeviceFactory.create.id, :sound => true, :badge => nil, :alert => s)
      noty.save!
      noty.alert.should start_with 'ΩΩΩ'
      noty.alert.should end_with 'ΩΩΩ...'
      noty.message_for_sending.bytesize.should == 255
    end

    it 'should truncate alert text more when custom dictionary added  to fit within 256 byte total message size limit' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create.id, :sound => true, :badge => nil, :alert => 'a' * 250, :payload => {:a => 'foo'})
      noty.save!
      noty.alert.should start_with 'aaa'
      noty.alert.should end_with 'aaa...'
      noty.message_for_sending.bytesize.should == 256
    end

  end

  describe 'apple_hash' do

    it 'should return a hash of the appropriate params for Apple' do
      noty = APN::Notification.first
      noty.apple_hash.should == {"aps" => {"badge" => 5, "sound" => "my_sound.aiff", "alert" => "Hello!"}}
      noty.badge = nil
      noty.apple_hash.should == {"aps" => {"sound" => "my_sound.aiff", "alert" => "Hello!"}}
      noty.alert = nil
      noty.apple_hash.should == {"aps" => {"sound" => "my_sound.aiff"}}
      noty.sound = nil
      noty.apple_hash.should == {"aps" => {}}
      noty.sound = true
      noty.apple_hash.should == {"aps" => {"sound" => "1.aiff"}}
    end

    it 'should include an optional payload' do
      payload = { :prop1 => 'value1', :prop2 => 2 }
      noty = APN::Notification.new :payload => payload

      noty.apple_hash.should == {"aps" => {}}.merge(payload)
    end

  end

  describe 'to_apple_json' do

    it 'should return the necessary JSON for Apple' do
      noty = APN::Notification.first
      noty.to_apple_json.should == %{{"aps":{"alert":"Hello!","badge":5,"sound":"my_sound.aiff"}}}
    end

    it 'should include an optional payload' do
      noty = APN::Notification.new :payload => { :prop1 => 'value1', :prop2 => 2 }
      noty.to_apple_json.should == %{{"aps":{},"prop1":"value1","prop2":2}}
    end

  end

  describe 'message_for_sending' do

    it 'should create a binary message to be sent to Apple' do
      noty = APN::Notification.first
      noty.device = DeviceFactory.new(:token => '5gxadhy6 6zmtxfl6 5zpbcxmw ez3w7ksf qscpr55t trknkzap 7yyt45sc g6jrw7qz')
      noty.message_for_sending.should == fixture_value('message_for_sending.bin')
    end

    it 'should raise an APN::Errors::ExceededMessageSizeError if the message is too big' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create.id, :sound => true, :badge => nil, :alert => 'a' * 250)
      lambda {
        noty.message_for_sending
      }.should raise_error(APN::Errors::ExceededMessageSizeError)
    end
  end

  describe 'send_notifications' do

    it 'should send the notifications in an Array' do

      notifications = [NotificationFactory.create, NotificationFactory.create]
      notifications.each_with_index do |notify, i|
        notify.stub(:message_for_sending).and_return("message-#{i}")
        notify.reload.sent_at.should be_nil
      end

      ssl_mock = mock('ssl_mock')
      ssl_mock.should_receive(:write).with('message-0message-1')
      APN::Connection.should_receive(:open_for_delivery).and_yield(ssl_mock, nil)
      notifications.stub(:find_each).and_yield(notifications.first).and_yield(notifications.last)

      APN::Notification.send_notifications(notifications)

      notifications.first.reload.sent_at.should_not be_nil
      notifications.last.reload.sent_at.should_not be_nil
    end

  end

end
