require 'active_doc'

module ActiveDoc
  module Rake
    # Defines a Rake tasks for generating RDoc documentation from active_doc.
    # User proc to load files you want to generate RDoc for.
    #
    # The simplest use of it goes something like:
    #
    #   ActiveDoc::Rake::Task.new do
    #     require 'file_one.rb' # files you want to describe
    #     require 'file_two.rb'
    #   end
    #
    #
    # This will define a task named <tt>active_doc</tt> described as 'Generate ActiveDoc RDoc documentation'. 
    class Task
      class GenerateRDocRunner #:nodoc:
        
        def initialize
        end
        
        def run
          ActiveDoc::RdocGenerator.write_rdoc do |file, documented_methods|
            STDOUT.puts "Generating RDoc for #{file}..."
          end
        end
      end
      
      def initialize(task_name = "active_doc", desc = "Generate ActiveDoc RDoc documentation")
        @task_name, @desc = task_name, desc
        yield self if block_given?
        define_task
      end

      def define_task #:nodoc:
        desc @desc
        task @task_name do
          runner.run
        end
      end

      def runner #:nodoc:
        GenerateRDocRunner.new
      end
    end
  end
end
