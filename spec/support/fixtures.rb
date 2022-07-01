require "erb"
require "yaml"

def fixture(name)
  spec_root = File.expand_path("..", File.dirname(__FILE__))
  fixture_path = File.join(spec_root, "fixtures", "#{name}.yml")
  content = File.read(fixture_path)
  template = ERB.new(content)
  yaml = template.result(binding)
  parameters = YAML.method(:safe_load).parameters
  has_permitted_classes = parameters.find { |(type, name)| name == :permitted_classes }
  if has_permitted_classes
    YAML.safe_load(yaml, permitted_classes: [Symbol])
  else
    YAML.safe_load(yaml, [Symbol])
  end
end
