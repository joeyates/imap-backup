require "erb"
require "yaml"

def fixture(name)
  spec_root = File.expand_path("..", File.dirname(__FILE__))
  fixture_path = File.join(spec_root, "fixtures", "#{name}.yml")
  content = File.read(fixture_path)
  template = ERB.new(content)
  yaml = template.result(binding)
  YAML.safe_load(yaml, [Symbol])
end
