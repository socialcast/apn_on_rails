require 'spec_helper'

describe APN::Config do

  context "defaults in test mode" do
    it { APN_CONFIG.port.should == 2195 }
    it { APN_CONFIG.passphrase.should == '' }
    it { APN_CONFIG.host.should == 'gateway.sandbox.push.apple.com' }
    it { APN_CONFIG.cert.should end_with 'config/apple_push_notification_development.pem' }
    it { APN_FEEDBACK_CONFIG.port.should == 2196 }
    it { APN_FEEDBACK_CONFIG.passphrase.should == '' }
    it { APN_FEEDBACK_CONFIG.host.should == 'feedback.sandbox.push.apple.com' }
    it { APN_FEEDBACK_CONFIG.cert.should end_with 'config/apple_push_notification_development.pem' }
  end
  context "when not using default values" do
    context "APN_CONFIG" do
      context 'port with integer' do
        before { APN_CONFIG.set(:port, 1234) }
        it { APN_CONFIG.port.should == 1234 }
      end
      context 'passphrase with string' do
        before { APN_CONFIG.set(:passphrase, 'supersecr3t') }
        it { APN_CONFIG.passphrase.should == 'supersecr3t' }
      end
    end
    context "APN_FEEDBACK_CONFIG" do
      context 'port with integer' do
        before { APN_FEEDBACK_CONFIG.set(:port, 1234) }
        it { APN_FEEDBACK_CONFIG.port.should == 1234 }
      end
      context 'passphrase with string' do
        before { APN_FEEDBACK_CONFIG.set(:passphrase, 'supersecr3t') }
        it { APN_FEEDBACK_CONFIG.passphrase.should == 'supersecr3t' }
      end
    end
  end
end
