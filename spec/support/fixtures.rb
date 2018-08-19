def fixture(name)
  spec_root = File.expand_path("..", File.dirname(__FILE__))
  fixture_path = File.join(spec_root, "fixtures", name + ".yml")
  fixture = File.read(fixture_path)
  YAML.load(fixture)
end
