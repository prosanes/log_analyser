# encoding: utf-8

require "test_utils"
require "logstash/filters/aggregate"

describe LogStash::Filters::Aggregate do
	extend LogStash::RSpec

	describe "simple start pattern and end pattern" do
		# The logstash config goes here.
		# At this time, only filters are supported.
		config <<-CONFIG
			filter {
				aggregate {
					enable_flush => true
					start_pattern => "%{INT:id} start"
					end_pattern => "%{INT:id} end"
				}
			}
		CONFIG

		sample("message" => [ "1234 start", "1234 end" ]) do
			insist { subject["id"] } == "1234"
			insist { subject["message"] } == "1234 start\n1234 end"
		end
	end
end
