require 'spec_helper'

describe 'APN Configuration' do

  context "defaults in test mode" do
    it { APN_CONFIG[:port].should == 2195 }
    it { APN_CONFIG[:passphrase].should == '' }
    it { APN_CONFIG[:host].should == 'gateway.sandbox.push.apple.com' }
    it { APN_CONFIG[:cert].should end_with 'config/apple_push_notification_development.pem' }
    it { APN_FEEDBACK_CONFIG[:port].should == 2196 }
    it { APN_FEEDBACK_CONFIG[:passphrase].should == '' }
    it { APN_FEEDBACK_CONFIG[:host].should == 'feedback.sandbox.push.apple.com' }
    it { APN_FEEDBACK_CONFIG[:cert].should end_with 'config/apple_push_notification_development.pem' }

    it { APN_CONFIG.should be_a Hash }
    it { APN_FEEDBACK_CONFIG.should be_a Hash }
  end

end
