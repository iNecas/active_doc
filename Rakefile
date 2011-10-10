$: << "./lib"
require 'active_doc/rake/task'

in_dir = File.expand_path("../lib", __FILE__)
out_dir = File.expand_path("../active_doc_out", __FILE__)
ActiveDoc::Rake::Task.new(in_dir, out_dir) do
  require 'active_doc'
end
