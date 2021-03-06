require 'watir-webdriver'
require 'watir-scroll'
require_relative 'dev_config'
require_relative 'Optparse'

module MyTest
  module Client
    extend self
    @config = MyTest::Config

    def run(options)
      @browser = Watir::Browser.new :chrome
      @browser.goto "#{@config::SITE[options.env.to_sym]}#{@config::TESTS[options.test.to_sym]}&#{options.debug}"

      select_timeslot
      checkout_button = @browser.link(data_id: 'checkout')
      @browser.scroll.to(checkout_button)
      checkout_button.click

      billing_fill
      payment_fill options.type

      if options.enable_final_checkout
        do_checkout
      end
    end

    def do_checkout
      wait_for_load_window
      finish_button = @browser.button(id: 'submit-btn')
      @browser.scroll.to(finish_button)
      finish_button.click
    end

    def payment_fill(type='check')
      if type === 'check'
        @browser.input(id: 'p_method_checkmo').click
      else
        cc = @config::USER[:cc]
        @browser.input(id: 'p_method_braintree').click
        wait_for_load_window

        @browser.select(id: 'braintree_cc_type').select_value cc[:type]
        @browser.text_field(id: 'braintree_cc_number').set cc[:number]
        @browser.text_field(id: 'braintree_cc_cid').set cc[:cvv]
        @browser.select(id: 'braintree_expiration').select_value cc[:expiration][:month]
        @browser.select(id: 'braintree_expiration_yr').select_value cc[:expiration][:year]
      end

      @browser.div(id: 'simplemodal-container').div(data_id: 'close_modal').click
      @browser.checkbox(id: 'agreement-1').click
    end

    def billing_fill
      manager = @browser.select(id: 'billing:manager')
      manager.wait_until_present
      manager.options[@config::CHECKOUT[:account_manager_location]].click

      user = @config::USER
      @browser.text_field(id: 'billing_firstname').set user[:first_name]
      @browser.text_field(id: 'billing_lastname').set user[:last_name]
      @browser.text_field(id: 'billing_email').set user[:email]
      @browser.text_field(id: 'billing_company').set user[:company]
      @browser.text_field(id: 'billing_street1').set user[:address][:line1]
      @browser.text_field(id: 'billing_street2').set user[:address][:line2]
      @browser.text_field(id: 'billing_city').set user[:address][:city]
      @browser.text_field(id: 'billing_postcode').set user[:address][:zipcode]
      @browser.select(id: 'billing_region_id').options[user[:address][:state_location]].click
      @browser.text_field(id: 'billing_telephone').set user[:telephone]
    end

    def select_timeslot
      @browser.text_field(data_id: 'event_calendar_date').click
      select_available_date
      check_availablity = @browser.span(data_id: 'calendar_check_availability_btn')

      # use RTA or handle failure
      if check_availablity.present?
        @browser.scroll.to(check_availablity)
        check_availablity.span(class: 'hs-button').click

        # make sure there are available times for this date (I haven't been able to recreate this issue, however)
        # results = @browser.div(id: calendar_availability_results)
        # if results.present? && results.text.include('No Results Found') # this needs to be updated
        #   select_next_available_date(@browser) # need to implement this
        # end
        # p results = @browser.div(id: calendar_availability_results).text

        results_panel = @browser.div(css:  '.calendar_availability_results-panel.currentPanel')
        results_panel.wait_until_present
        results_panel.span(class: 'hs-button', data_class: 'applyAvailableDate').click
      elsif @browser.span(data_id: 'time_picker_wrapper').present?
        @browser.select(data_id: 'event_calendar_hour').select_value 1
        @browser.select(data_id: 'event_calendar_minute').select_value 0
        @browser.select(data_id: 'event_calendar_day_part').select_value 'pm'
      end

      select_options
    end

    def select_available_date
      @browser.div(css:  '.Zebra_DatePicker.dp_visible:not(.masked)').wait_until_present

      table = @browser.table class: 'dp_daypicker'
      if table.td(class: '').present?
        table.td(class: '').click
      else
        @browser.table(class: 'dp_header').td(class: 'dp_next').click
        select_available_date
      end
    end

    def select_options
      options = @browser.divs(class: 'input-box')
      options.each do |option|
        if option.radio.present?
          option.radio.click
        end
      end

      # TODO not currently transferable to other events (currently blues-jean-bar-dallas-retail event)
      # TODO should add an automation tag to this
      [
          @browser.checkbox(:xpath => '//*[@id="options_21550_2"]'),
          @browser.checkbox(:xpath => '//*[@id="options_21550_3"]'),
      ].each do |option|
        if option.present?
          option.set
        end
      end
    end

    def wait_for_load_window
      Watir::Wait.until {
        !@browser.div(class: 'loadinfo').present?
      }
    end
  end
end

options = OptparseCheckout.parse(ARGV)
MyTest::Client.run options
