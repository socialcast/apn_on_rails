require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'spec_helper.rb')

describe APN::Notification do
  
  describe 'truncate_alert' do
    
    it 'should truncate alert text to fit in 255 byte payload' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create, :sound => true, :badge => nil, :alert => 'a' * 250)
      noty.save!
      noty.alert.should == ('a' * 215) + '...'
      noty.to_apple_json.size.should == 255
      #should not raise error
      noty.message_for_sending
    end

    it 'should truncate very long unicode alert text to fit in 255 byte payload' do
      s = "Ω" * 250
      noty = NotificationFactory.new(:device_id => DeviceFactory.create, :sound => true, :badge => nil, :alert => s)
      noty.save!
      noty.alert.should == ("Ω" * 35) + '...'
      noty.to_apple_json.size.should == 250
      #should not raise error
      noty.message_for_sending
    end

    it 'should truncate alert text more when custom dictionary added to fit in 255 byte payload' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create, :sound => true, :badge => nil, :alert => 'a' * 250, :payload => {:a => 'foo'})
      noty.save!
      noty.alert.should == ('a' * 205) + '...'
      noty.to_apple_json.size.should == 255
      #should not raise error
      noty.message_for_sending
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
      noty.to_apple_json.should == %{{"aps":{"badge":5,"sound":"my_sound.aiff","alert":"Hello!"}}}
    end
    
    it 'should include an optional payload' do
      noty = APN::Notification.new :payload => { :prop1 => 'value1', :prop2 => 2 }
      noty.to_apple_json.should == %{{"prop1":"value1","aps":{},"prop2":2}}
    end

  end
  
  describe 'message_for_sending' do
    
    it 'should create a binary message to be sent to Apple' do
      noty = APN::Notification.first
      noty.device = DeviceFactory.new(:token => '5gxadhy6 6zmtxfl6 5zpbcxmw ez3w7ksf qscpr55t trknkzap 7yyt45sc g6jrw7qz')
      noty.message_for_sending.should == fixture_value('message_for_sending.bin')
    end
    
    it 'should raise an APN::Errors::ExceededMessageSizeError if the message is too big' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create, :sound => true, :badge => nil, :alert => 'a' * 250)
      lambda {
        noty.message_for_sending
      }.should raise_error(APN::Errors::ExceededMessageSizeError)
    end
    
    it 'should raise an APN::Errors::ExceededMessageSizeError with overage attribute if the message is too big' do
      noty = NotificationFactory.new(:device_id => DeviceFactory.create, :sound => true, :badge => nil, :alert => 'a' * 250)
      begin
        noty.message_for_sending
        flunk 'error should be raised'
      rescue APN::Errors::ExceededMessageSizeError => e
        e.overage.should == 32
      end
    end
    
  end
  
  describe 'send_notifications' do
    
    it 'should send the notifications in an Array' do
      
      notifications = [NotificationFactory.create, NotificationFactory.create]
      notifications.each_with_index do |notify, i|
        notify.stub(:message_for_sending).and_return("message-#{i}")
        notify.should_receive(:sent_at=).with(instance_of(Time))
        notify.should_receive(:save)
      end
      
      ssl_mock = mock('ssl_mock')
      ssl_mock.should_receive(:write).with('message-0')
      ssl_mock.should_receive(:write).with('message-1')
      APN::Connection.should_receive(:open_for_delivery).and_yield(ssl_mock, nil)
      
      APN::Notification.send_notifications(notifications)
      
    end
    
  end
  
end