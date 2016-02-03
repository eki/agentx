
module AgentX
  class Console
    attr_reader :options

    def initialize(options={})
      @options = options
    end

    def load_config
      unless options[:config]
        options[:config] = "#{AgentX.root}/config"

        unless File.exists?(options[:config])
          example = 
            File.expand_path('../../config.example', File.dirname(__FILE__))
          FileUtils.cp(example, options[:config])
          FileUtils.chmod(0600, options[:config])
        end
      end

      self.class.load(options[:config])
    end

    def self.load(filename)
      class_eval(File.read(filename))
    end

    def credentials
      return @credentials if @credentials

      if File.exists?(yaml = "#{AgentX.root}/credentials.yml")
        @credentials = YAML.load_file(yaml)
      elsif File.exists?(json = "#{AgentX.root}/credentials.json")
        @credentials = Oj.load(File.read(json))
      else
        @credentials = {}
        File.open(yaml, 'w') { |f| f.write(@credentials.to_yaml) }
      end

      @credentials
    end

  end
end

