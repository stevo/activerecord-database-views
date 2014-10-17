require 'erb'

module ActiveRecord::DatabaseViews
  class View
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def drop!
      call_sql!("DROP VIEW IF EXISTS #{name} CASCADE;")
    end

    def load!
      call_sql!("CREATE OR REPLACE VIEW #{name} AS #{sql};")
    end

    def name
      File.basename(File.basename(path, '.erb'), '.sql')
    end

    private

    def full_path
      Rails.root.join(path)
    end

    def sql
      if File.extname(path) == '.erb'
        ERB.new(File.read(full_path)).result
      else
        File.read(full_path)
      end
    end

    def call_sql!(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
