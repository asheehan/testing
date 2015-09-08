require 'watir-webdriver'
require 'watir-scroll'
require_relative 'dev_config'
require_relative 'Optparse'

module MyTest
  module Client
    extend self
    @config = MyTest::Config

    def run(options)
      b = Watir::Browser.new :chrome
      b.goto "#{@config::SITE[options.env.to_sym]}#{@config::TESTS[options.test.to_sym]}&#{options.debug}"

      select_timeslot(b)
      checkout_button = b.link(data_id: 'checkout')
      b.scroll.to(checkout_button)
      checkout_button.click

      billing_fill(b)
      payment_fill(b, options.type)
      if options.enable_final_checkout
        do_checkout(b)
      end
    end

    def do_checkout(browser)
      wait_for_load_window(browser)
      finish_button = browser.button(id: 'submit-btn')
      browser.scroll.to(finish_button)
      finish_button.click
    end

    def payment_fill(browser, type='check')
      if type === 'check'
        browser.input(id: 'p_method_checkmo').click
        browser.checkbox(id: 'agreement-1').click
      else
        cc = @config::USER[:cc]
        browser.input(id: 'p_method_braintree').click
        wait_for_load_window(browser)

        browser.select(id: 'braintree_cc_type').select_value cc[:type]
        browser.text_field(id: 'braintree_cc_number').set cc[:number]
        browser.text_field(id: 'braintree_cc_cid').set cc[:cvv]
        browser.select(id: 'braintree_expiration').select_value cc[:expiration][:month]
        browser.select(id: 'braintree_expiration_yr').select_value cc[:expiration][:year]
        browser.checkbox(id: 'agreement-1').click
      end

      if browser.div(id: 'invoice-alert').present?
        browser.div(id: 'invoice-alert').link(class: 'hs-button').click
      end
    end

    def billing_fill(browser)
      manager = browser.select(id: 'billing:manager')
      manager.wait_until_present
      manager.options[@config::CHECKOUT[:account_manager_location]].click

      user = @config::USER
      browser.text_field(id: 'billing_firstname').set user[:first_name]
      browser.text_field(id: 'billing_lastname').set user[:last_name]
      browser.text_field(id: 'billing_email').set user[:email]
      browser.text_field(id: 'billing_company').set user[:company]
      browser.text_field(id: 'billing_street1').set user[:address][:line1]
      browser.text_field(id: 'billing_street2').set user[:address][:line2]
      browser.text_field(id: 'billing_city').set user[:address][:city]
      browser.text_field(id: 'billing_postcode').set user[:address][:zipcode]
      browser.select(id: 'billing_region_id').options[user[:address][:state_location]].click
      browser.text_field(id: 'billing_telephone').set user[:telephone]
    end

    def select_timeslot(browser)
      browser.text_field(data_id: 'event_calendar_date').click
      select_available_date(browser)
      check_availablity = browser.span(data_id: 'calendar_check_availability_btn')

      # use RTA or handle failure
      if check_availablity.present?
        browser.scroll.to(check_availablity)
        check_availablity.span(class: 'hs-button').click

        # make sure there are available times for this date
        # results = browser.div(id: calendar_availability_results)
        # if results.present? && results.text.include('No Results Found') # this needs to be updated
        #   select_next_available_date(browser) # need to implement this
        # end
        # p results = browser.div(id: calendar_availability_results).text

        results_panel = browser.div(css:  '.calendar_availability_results-panel.currentPanel')
        results_panel.wait_until_present
        results_panel.span(class: 'hs-button', data_class: 'applyAvailableDate').click
      elsif browser.span(data_id: 'time_picker_wrapper').present?
        browser.select(data_id: 'event_calendar_hour').select_value 1
        browser.select(data_id: 'event_calendar_minute').select_value 0
        browser.select(data_id: 'event_calendar_day_part').select_value 'pm'
      end

      select_options(browser)
    end

    def select_available_date(browser)
      browser.div(css:  '.Zebra_DatePicker.dp_visible:not(.masked)').wait_until_present

      table = browser.table class: 'dp_daypicker'
      if table.td(class: '').present?
        table.td(class: '').click
      else
        browser.table(class: 'dp_header').td(class: 'dp_next').click
        select_available_date(browser)
      end
    end

    def select_options(browser)
      options = browser.divs(class: 'input-box')
      options.each do |option|
        if option.radio.present?
          option.radio.click
        end
      end

      # TODO not currently transferable to other events (currently blues-jean-bar-dallas-retail event)
      [
          browser.checkbox(:xpath => '//*[@id="options_21550_2"]'),
          browser.checkbox(:xpath => '//*[@id="options_21550_3"]'),
      ].each do |option|
        if option.present?
          option.set
        end
      end
    end

    def wait_for_load_window(browser)
      Watir::Wait.until {
        !browser.div(class: 'loadinfo').present?
      }
    end
  end
end

options = OptparseCheckout.parse(ARGV)
MyTest::Client.run options
