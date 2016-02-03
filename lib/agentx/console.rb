
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

  end
end

