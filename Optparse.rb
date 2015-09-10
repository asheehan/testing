require 'optparse'
require 'ostruct'
require_relative 'dev_config'

class OptparseCheckout
  @config = MyTest::Config

  def self.parse(args)
    options = OpenStruct.new
    options.env = 'dev'
    options.type = 'credit'
    options.email = @config::USER[:email]
    options.test = 'event'
    options.debug = ''
    options.enable_final_checkout = true

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: ruby checkout.rb [options]"

      opts.separator " "
      opts.separator "Specific options:"

      opts.on('-e', '--environment ENVIRONMENT', 'Testing Environment') do |e|
        options.env = e
      end
      opts.on('-a', '--check', 'Use Check/ACH') do |c|
        options.type = 'check'
      end
      opts.on('-m', '--email EMAIL_ADDRESS', 'Email Address') do |m|
        options.email = m
      end
      opts.on('-t', '--test TEST_ENVIRONMENT', 'Test to Run') do |t|
        options.test = t
      end
      opts.on('-d', '--debug', 'Enable Debugging') do |d|
        options.debug = 'XDEBUG_SESSION_START=phpstorm'
      end
      opts.on('-c', '--no-checkout', 'Disable Final Checkout') do |c|
        options.enable_final_checkout = false
      end
    end

    opt_parser.parse!(args)
    options
  end
end