require 'fileutils'
require "net/http"
require 'nokogiri'
require 'zip'

module JmeterTestRunner
  class Test

    attr_accessor :jmeter_test_plan, :jmeter_test_result, :jmeter_test_result_format
    attr_accessor :jmeter_version, :jmeter_installer, :jmeter_binary_url, :jmeter_workspace, :jmeter_install_folder, :jmeter_executable_file, :jmeter_xslt_template_file
    attr_accessor :jmeter_standard_plugin, :jmeter_standard_plugin_url, :jmeter_extras_plugin, :jmeter_extras_plugin_url
    attr_reader :jmeter_path, :jmeter_standard_plugin_file, :jmeter_extras_plugin_file, :jmeter_path, :jmeter_command, :jmeter_options
    
    def initialize(jmeter_test_plan, jmeter_test_result, jmeter_test_result_format, summary_report_format='html', summary_report_file='', options={}, jmeter_version='2.12')
      @jmeter_test_plan = jmeter_test_plan
      @jmeter_test_result = jmeter_test_result
      @jmeter_test_result_format = jmeter_test_result_format
      @jmeter_version = jmeter_version
      @jmeter_installer = "apache-jmeter-#{@jmeter_version}.zip"
      @jmeter_binary_url = "http://ftp.itu.edu.tr/Mirror/Apache//jmeter/binaries/#{@jmeter_installer}"
      @jmeter_standard_plugin = "JMeterPlugins-Standard-1.2.0.zip"
      @jmeter_standard_plugin_url = "http://jmeter-plugins.org/downloads/file/#{@jmeter_standard_plugin}"
      @jmeter_extras_plugin = "JMeterPlugins-Extras-1.2.0.zip"
      @jmeter_extras_plugin_url = "http://jmeter-plugins.org/downloads/file/#{@jmeter_extras_plugin}"
      @jmeter_workspace = ENV['HOME']
      @jmeter_install_folder = "apache-jmeter-#{jmeter_version}"
      @jmeter_executable_file = "jmeter"
      @jmeter_standard_plugin_file = File.join(@jmeter_workspace, @jmeter_install_folder, "lib", "ext", "JMeterPlugins-Standard.jar")
      @jmeter_extras_plugin_file = File.join(@jmeter_workspace, @jmeter_install_folder, "lib", "ext", "JMeterPlugins-Extras.jar")
      @jmeter_path = File.join(@jmeter_workspace, @jmeter_install_folder, "bin")
      @jmeter_command = File.join(@jmeter_path, @jmeter_executable_file)
      @jmeter_options = options
      @jmeter_xslt_template_file = File.join(@jmeter_workspace, @jmeter_install_folder, "extras", "jmeter-results-report_21.xsl")
      @jmeter_summary_format = summary_report_format
      @jmeter_summary_output_file = summary_report_file
      @jmeter_reporter_tool = File.join(@jmeter_workspace, @jmeter_install_folder, "lib", "ext", "CMDRunner.jar")
    end
    
    def start
      begin
        remove_old_benchmark_results(@jmeter_test_result, @jmeter_summary_output_file)
        install_jmeter unless is_jmeter_installed?
        install_jmeter_standard_plugin unless is_jmeter_standard_plugin_installed?
        install_jmeter_extras_plugin unless is_jmeter_extras_plugin_installed?
        execute_jmeter_test(@jmeter_test_plan, @jmeter_test_result, @jmeter_test_result_format, @jmeter_options)
        case @jmeter_summary_format
        when 'html'
          unless @jmeter_summary_output_file.empty?
            create_html_report(@jmeter_summary_output_file)
          end 
        when 'csv' 
          unless @jmeter_summary_output_file.empty?
            create_csv_report(@jmeter_summary_output_file)
          end
        else
          puts "\nWarning!! Invalid Report format \'#{@jmeter_summary_format}\'. Report will NOT be generated!\n"
        end 
      rescue => exception
        puts exception.message
        puts exception.backtrace
      end
    end
    
    def install
      install_jmeter unless is_jmeter_installed?
      install_jmeter_standard_plugin unless is_jmeter_standard_plugin_installed?
      install_jmeter_extras_plugin unless is_jmeter_extras_plugin_installed?
    end
    
    def is_windows?
      (/linux|darwin/ =~ RUBY_PLATFORM) == nil
    end

    def is_not_windows?
      !is_windows?
    end
    
    def unzip_file(zipped_file, destination)
      puts "Unzipping file: #{zipped_file} to location: #{destination}"
      Zip::File.open(zipped_file) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(destination, f.name)
          puts "Extracting #{f.name} to .......#{f_path}"
          FileUtils.mkdir_p(File.dirname(f_path))
          f.extract(f_path) 
        end
      end
    end
    
    def download(download_url, save_as_file_name)
    end
    
    def remove_old_benchmark_results(jmeter_test_result_file, jmeter_report_file)
      puts "\nClearing old JMeter test result file ...\n"
      FileUtils.rm_f(jmeter_test_result_file)
      FileUtils.rm_f(jmeter_report_file)
    end
    
    def is_jmeter_installed?
      puts "\nChecking for presence of jmeter executable file #{@jmeter_command}\n"
      jmeter_installed = File.file? "#{@jmeter_command}"
      #if !is_os_supported?
      #  if !jmeter_installed
      #    puts "\nJmeter not found (in folder #{@jmeter_workspace})."
      #    puts "This gem cannot install jmeter automatically on this OS (yet..coming soon!)."
      #    puts "Please install jmeter (version #{@jmeter_version}) manually into folder #{@jmeter_workspace}\n"
      #    raise "\nCannot proceed. Hence exiting...\n"
      #  end
      #end
      return jmeter_installed
    end
    
    def is_jmeter_standard_plugin_installed?
      puts "\nChecking for presence of jmeter standard plugin #{@jmeter_standard_plugin_file}\n"
      return File.file? "#{@jmeter_standard_plugin_file}"
    end
    
    def is_jmeter_extras_plugin_installed?
      puts "\nChecking for presence of jmeter extras plugin #{@jmeter_extras_plugin_file}\n"
      return File.file? "#{@jmeter_extras_plugin_file}"
    end
    
    def install_jmeter
      puts "\nInstalling JMeter...\n"
      FileUtils.mkdir_p @jmeter_workspace
      Dir.chdir(@jmeter_workspace) do
        `curl -LOk #{@jmeter_binary_url}`
        unzip_file(@jmeter_installer, @jmeter_workspace)
        if is_not_windows?
          `chmod +x #{@jmeter_command}`
        end
      end
      puts "\nJMeter installed into folder #{@jmeter_workspace} ...\n"
    end
    
    def install_jmeter_standard_plugin
      puts "\nInstalling JMeter Standard plugin...\n"
      Dir.chdir(File.join(@jmeter_workspace, @jmeter_install_folder)) do
          `curl -LOk #{@jmeter_standard_plugin_url}`
          unzip_file(@jmeter_standard_plugin, File.join(@jmeter_workspace,@jmeter_install_folder))
      end
      puts "\nJMeter Standard plugin installed into folder #{File.join(@jmeter_workspace,@jmeter_install_folder)} ...\n"
    end
    
    def install_jmeter_extras_plugin
      puts "\nInstalling JMeter Extras plugin...\n"
      Dir.chdir(File.join(@jmeter_workspace, @jmeter_install_folder)) do
          `curl -LOk #{@jmeter_extras_plugin_url}`
          unzip_file(@jmeter_extras_plugin, File.join(@jmeter_workspace,@jmeter_install_folder))
      end
      puts "\nJMeter Extras plugin installed into folder #{File.join(@jmeter_workspace,@jmeter_install_folder)} ...\n"
    end
    
    def create_options(options)
      options_string=""
      options.each do |key, value|
        options_string += "-J#{key}=#{value}"
        options_string += " "
      end
      return options_string.strip()
    end
    
    def execute_jmeter_test(test_plan, results_file, results_format, options)
      start_time = Time.now
      puts "\nExecuting JMeter test ...\n"
      options_string = ''
      options_string = create_options(options) unless options.empty?
      command_to_execute = "#{@jmeter_command} -n #{options_string} -Jjmeter.save.saveservice.output_format=#{results_format} -t #{test_plan} -l #{results_file}"
      puts "\n#{command_to_execute}\n"
      `#{command_to_execute}`
      puts "\nJMeter test completed ..., took #{(Time.now-start_time).to_i} seconds\n"
    end
    
    def create_html_report(output_file)
      start_time = Time.now
      template = Nokogiri::XSLT(File.read(@jmeter_xslt_template_file))
      document = Nokogiri::XML(File.read(@jmeter_test_result))
      transformed_document = template.transform(document)
      File.open(output_file, 'w').write(transformed_document)
      puts "\nGenerated html report #{output_file}, took #{(Time.now-start_time).to_i} seconds to generate report\n"
    end
    
    def create_csv_report(output_file)
      start_time = Time.now
      command_to_execute = "java -jar #{@jmeter_reporter_tool} --tool Reporter --generate-csv #{output_file} --input-jtl #{@jmeter_test_result} --plugin-type AggregateReport"
      puts "\n#{command_to_execute}\n"
      `#{command_to_execute}`
      puts "\nGenerated csv report #{output_file}, took #{(Time.now-start_time).to_i} seconds to generate report\n"
    end
    
  end
end
