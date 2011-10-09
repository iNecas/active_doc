def class_with_active_doc(&block)
  klass = Class.new do
    include ActiveDoc
  end
  klass.class_eval(&block)
  klass
end
