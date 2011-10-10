require 'active_doc'

module ActiveDoc
  module Rake
    # Defines a Rake tasks for generating RDoc documentation from active_doc.
    # User proc to load files you want to generate RDoc for.
    #
    # The simplest use of it goes something like:
    #
    #   in_dir = File.expand_path("../lib", __FILE__)
    #   out_dir = File.expand_path("../active_doc_out", __FILE__)
    #   ActiveDoc::Rake::Task.new(in_dir, out_dir) do
    #     require 'file_one.rb' # files you want to describe
    #     require 'file_two.rb'
    #   end
    #
    #
    # This will define a task named <tt>active_doc</tt> described as 'Generate ActiveDoc RDoc documentation'. 
    class Task
      class GenerateRDocRunner #:nodoc:

        def initialize(source_dir, output_dir)
          @source_dir, @output_dir = source_dir, output_dir
        end

        def run
          ActiveDoc::RdocGenerator.write_rdoc_for_dir(@source_dir, @output_dir) do |file, documented_methods|
            STDOUT.puts "Generating RDoc for #{file}..."
          end
        end
      end

      def initialize(source_dir, output_dir, task_name = "active_doc", desc = "Generate ActiveDoc RDoc documentation")
        @source_dir, @output_dir = source_dir, output_dir
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
        GenerateRDocRunner.new(@source_dir, @output_dir)
      end
    end
  end
end
