class ActiveRecord::Base
  MISSING_RELATION_REGEX = /relation \"(.*)\" does not exist/
  class << self

    #===========================================
    #============= Functions ===================
    #===========================================

    def reload_functions!
      drop_functions!
      load_functions!
    end

    def without_functions(&block)
      drop_functions!
      block.call
      load_functions!
    end

    def drop_functions!
      init_functions
      @functions_to_load.keys.each do |function_name|
        path = @functions_to_load[function_name]
        sql = File.read(path)
        function_name = sql.match(/FUNCTION (.*) RETURNS/)[1]
        connection.execute("DROP FUNCTION IF EXISTS #{function_name} CASCADE;")
      end
    end

    def load_functions!
      init_functions
      while @functions_to_load.present?
        function_name = @functions_to_load.keys.first
        load_function(function_name)
      end
    end

    private

    def load_function(function_name)
      path = @functions_to_load[function_name]
      Rails.logger.info "\nLOADING VIEW: #{function_name} (#{path}) \n#{'-' * 100}"
      sql = File.read(path)
      connection.execute(sql)
      @functions_to_load.delete(function_name)
      Rails.logger.info "\nFUNCTION LOADED SUCCESSFULLY"
    end

    def init_functions
      @functions_to_load = Dir.glob("db/functions/**/*.sql").inject({}) do |acc, path|
        acc[File.basename(path, '.sql')] = Rails.root.join(path); acc
      end
    end

    #=======================================
    #============= Views ===================
    #=======================================

    public

    def reload_views!
      reload_functions!
      drop_views!
      load_views!
    end

    def without_views(&block)
      drop_views!
      block.call
      load_views!
    end

    def drop_views!
      init_views
      @views_to_load.keys.each do |view_name|
        connection.execute("DROP VIEW IF EXISTS #{view_name} CASCADE;")
      end
    end

    #This is weird, but some views were imported as tables during one import...
    def drop_views_as_tables!
      init_views
      @views_to_load.keys.each do |view_name|
        begin
          connection.execute("DROP TABLE IF EXISTS #{view_name} CASCADE;")
        rescue ActiveRecord::StatementInvalid => exc
          if exc.message[%{"#{view_name}" is not a table}]
            connection.execute("DROP VIEW IF EXISTS #{view_name} CASCADE;")
          else
            raise exc
          end
        end
      end
    end

    def load_views!
      init_views
      while @views_to_load.present?
        view_name = @views_to_load.keys.first
        load_view(view_name)
      end
    end

    private

    def load_view(view_name)
      begin
        path = @views_to_load[view_name]

        Rails.logger.info "\nLOADING VIEW: #{view_name} (#{path}) \n#{'-' * 100}"
        sql = File.read(path)
        Rails.logger.info("\n\n #{sql}")

        connection.execute("CREATE OR REPLACE VIEW #{view_name} AS #{sql};")
        Rails.logger.info "\nVIEW LOADED SUCCESSFULLY"

        @views_to_load.delete(view_name)
      rescue ActiveRecord::StatementInvalid => exc
        related_view_name = exc.message.scan(MISSING_RELATION_REGEX).flatten.first
        if @views_to_load[related_view_name].present?
          load_view(related_view_name)
          retry
        else
          raise exc
        end
      end
    end

    def init_views
      @views_to_load = Dir.glob("db/views/**/*.sql").inject({}) do |acc, path|
        acc[File.basename(path, '.sql')] = Rails.root.join(path); acc
      end
    end

  end
end
