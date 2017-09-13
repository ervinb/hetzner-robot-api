require "spec_helper"

FactoryGirl.define do
  factory :server, class: OpenStruct do
    ignore do
      sequence(:server_ip) {|n| "1.2.3.#{n}"}
      sequence(:server_number) {|n| n }
      server_name   ""
      product       "EX41S-SSD"
      dc            "10"
      traffic       "30 TB"
      flatrate      true
      status        "ready"
      throttled     false
      cancelled     false
      paid_until    "2017-09-07"
    end

    initialize_with do
      new(:server => OpenStruct.new(
        :server_ip     => server_ip,
        :server_number => server_number,
        :server_name   => server_name,
        :product       => product,
        :dc            => dc,
        :traffic       => traffic,
        :flatrate      => flatrate,
        :status        => status,
        :throttled     => throttled,
        :cancelled     => cancelled,
        :paid_until    => paid_until
        )
      )
    end
  end
end
