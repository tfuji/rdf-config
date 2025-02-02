require 'yaml'
require 'pathname'

class RDFConfig
  class Config
    CONFIG_NAMES = %i[model sparql prefix endpoint stanza metadata schema].freeze

    CONFIG_NAMES.each do |name|
      define_method name do
        instance_varname = "@#{name}"
        instance_variable_get(instance_varname) ||
          instance_variable_set(instance_varname, read_config(config_file_path(name)))
      rescue Psych::SyntaxError => e
        raise SyntaxError, "Invalid YAML format #{e.message}"
      end
    end

    attr_reader :config_dir

    def initialize(config_dir, opts = {})
      config_dirs = if config_dir.is_a?(Array)
                      config_dir
                    else
                      [config_dir.to_s]
                    end

      not_found_config_dirs = []
      config_dirs.each do |dir_path|
        not_found_config_dirs << dir_path unless File.exist?(dir_path)
      end
      unless not_found_config_dirs.empty?
        raise ConfigNotFound, "Config directory (#{not_found_config_dirs.join(', ')}) does not exist."
      end

      @config_dir = config_dir
      @opts = opts
    end

    def exist?(name)
      config_file_path(name)
      true
    rescue ConfigNotFound
      false
    end

    def name
      File.basename(@config_dir)
    end

    private

    def config_file_path(name)
      fpath = Pathname.new(@config_dir).join("#{name}.yaml").to_path
      raise ConfigNotFound, "Config file (#{fpath}) does not exist." unless File.exist?(fpath)

      fpath
    end

    def read_config(config_file_path)
      config = if Gem::Version.create(RUBY_VERSION) >= Gem::Version.create('3.1')
                 require 'date'
                 YAML.load_file(config_file_path, permitted_classes: [Date])
               else
                 YAML.load_file(config_file_path)
               end

      if !config.is_a?(Hash) && !config.is_a?(Array)
        raise InvalidConfig, "Config file (#{config_file_path}) is not a valid YAML file."
      end

      config
    end

    class ConfigNotFound < StandardError; end
    class SyntaxError < StandardError; end
    class InvalidConfig < StandardError; end
  end
end
