# JmeterTestRunner

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

	gem 'jmeter-test-runner', :git => 'https://github.com/hdushan/jmeter-test-runner.git'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jmeter-test-runner

## Usage

Typical usage in a Rake task:

```ruby
desc "Run Jmeter Performance Tests"
task :performance do |t |
  require 'jmeter-test-runner'
  puts "Running Load Test"
  loadtest_script = "performance/loadtest.jmx"
  result_file = "loadtest_results.jtl"
  result_file_html = "loadtest_results.html"
  run_load_test(loadtest_script, result_file, "xml", result_file_html)
  check_for_errors(result_file_html, 98)
end

def check_for_errors(result_file_html, threshold)
  require 'nokogiri'
  page = Nokogiri::HTML(open(result_file_html)) 
  puts page.text.include?("Test Results")
  pass_percent = page.css(".details")[0].css("td")[2].text.split("%")[0].to_i
  if pass_percent < threshold
    puts "\n\nFAIL!!!!!!\nPass percentage of http requests (#{pass_percent}%) is less than the expected threshold (#{threshold}%)\n\n"
    raise
  end  
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
