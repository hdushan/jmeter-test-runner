# JmeterTestRunner

Starts jmeter in non-GUI mode and runs a test plan. Creates csv or html summary report.

## Installation

Add this line to your application's Gemfile:

  `gem 'jmeter-test-runner', :git => 'https://github.com/hdushan/jmeter-test-runner.git'`

And then execute:

   `bundle install`

## Usage

Typical usage in a Rake task:

```ruby
desc "Run Jmeter Performance Tests (Desktop)"
task :performance, [:server_url, :max_load, :ramup_up, :duration, :pass_percentage] do |t, args |
  require 'jmeter-test-runner'
  loadtest_script = "performance/loadtest.jmx"
  result_file = "loadtest_results.jtl"
  report_file = "loadtest_report.csv"
  options = {}
  options["SERVER_URL"] = args[:server_url]
  options["MAX_LOAD"] = args[:max_load]
  options["RAMP_UP"] = args[:ramup_up]
  options["DURATION"] = args[:duration] 
  run_load_test(loadtest_script, result_file, "csv", report_file, options)
  expected_pass_percentage = args[:pass_percentage].to_i
  check_for_errors("csv", report_file, expected_pass_percentage)
  rescue => e
    puts e.to_s
    abort("\nLoad test not successful\n")
  end  
end

def check_for_errors(report_file_format, report_file, threshold)
  case report_file_format
    when "html"
      require 'nokogiri'
      page = Nokogiri::HTML(open(report_file))
      pass_percent = page.css(".details")[0].css("td")[2].text.split("%")[0].to_i
    when "csv"
      require 'csv'
      result_table = CSV.table(report_file)
      last_row_that_has_totals = result_table[-1]
      total_error_rate_as_a_percentage = last_row_that_has_totals.to_hash[:aggregate_report_error]*100
      pass_percent = (100-total_error_rate_as_a_percentage).round(2)
    else
      puts "\n\nWarning: Invalid report format \'#{report_file_format}\'. Cannot calculate pass percentage!!\n\n"
  end
  if defined? pass_percent
    puts "\n\nOverall Pass percentage: #{pass_percent}%\n\n"
    if pass_percent < threshold
      raise "\n\nFAIL!!!!!!\nPass percentage of http requests (#{pass_percent}%) is less than the expected threshold (#{threshold}%)\n\n"
    end
  end  
end

def run_load_test(loadtest_file, loadtest_result_file, loadtest_report_format, loadtest_report_file, options='')
  jmeter_result_format = "xml"
  testRunner = JmeterTestRunner::Test.new(loadtest_file, loadtest_result_file, jmeter_result_format, loadtest_report_format, loadtest_report_file, options)
  testRunner.start()
end
```

Complete list of things that are configurable:
```ruby

  testRunner = JmeterTestRunner::Test.new
  testRunner.configure do |t|
    t.jmeter_test_plan = "perf/abcd.jmx"
    t.jmeter_test_result = "abcd.jtl"
    t.jmeter_test_result_format = "xml"
    t.jmeter_installer = "apache-jmeter-2.12.zip"
    t.jmeter_binary_url = "http://ftp.itu.edu.tr/Mirror/Apache//jmeter/binaries/apache-jmeter-2.12.zip"
    t.jmeter_standard_plugin = "JMeterPlugins-Standard-1.2.0.zip"
    t.jmeter_standard_plugin_url = "http://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-1.2.0.zip"
    t.jmeter_extras_plugin = "JMeterPlugins-Extras-1.2.0.zip"
    t.jmeter_extras_plugin_url = "http://jmeter-plugins.org/downloads/file/JMeterPlugins-Extras-1.2.0.zip"
    t.jmeter_workspace = ENV['HOME']
    t.jmeter_install_folder = "apache-jmeter-2.12"
    t.jmeter_executable_file = "jmeter"
    t.jmeter_options = {"jmeter.save.saveservice.output_format" => "xml", "SERVER" => "test.com"}
  end
  testRunner.start()
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
