module ActiveRecord::DatabaseViews
  class ViewCollection
    MISSING_RELATION_REGEX = /relation \"(.*)\" does not exist/
    MISSING_VIEW_REGEX = /view \"(.*)\" does not exist/
    DROP_COLUMNS_REGEX = /cannot drop columns from view/
    CHANGE_COLUMNS_REGEX = /cannot change name of view column \"(.*)\" to \"(.*)\"/
    UNDEFINED_COLUMN_REGEX = /column (.*) does not exist/

    include Enumerable

    attr_reader :views

    delegate :each, to: :views

    def initialize
      @views = view_paths.map { |path| View.new(path) }
    end

    def drop!
      each(&:drop!)
    end

    def load!
      load_view(first) while first
    end

    private

    def load_view(view)
      name = view.name

      begin
        view.load! and views.delete(view)
        puts "#{name}: Loaded"
      rescue ActiveRecord::StatementInvalid => exception
        ActiveRecord::Base.connection.rollback_db_transaction

        if schema_changed?(exception)
          puts "#{name}: Column definitions have changed"
          # Drop the view
          view.drop!
          # Load it again
          load_view(view)
        elsif undefined_column?(exception)
          puts "#{name}: Undefined column"
          # Drop all the remaining views since we can't detect which one it is
          views.each(&:drop!)
          # Load the view again (which will trigger a missing relation error and proceed to load that view)
          load_view(view)
        elsif (related_view = retrieve_related_view(exception))
          puts "#{name}: Contains missing relation"
          # Load the relation that is mentioned
          load_view(related_view) and retry
        elsif (related_view = retrieve_missing_view(exception))
          puts "#{name}: Contains missing view"
          # Load the view that is mentioned
          load_view(related_view) and retry
        else
          raise exception
        end
      end
    end

    def retrieve_related_view(exception)
      related_view_name = exception.message.scan(MISSING_RELATION_REGEX).flatten.first
      return false if related_view_name.blank?
      find { |view| view.name == related_view_name }
    end

    def retrieve_missing_view(exception)
      related_view_name = exception.message.scan(MISSING_VIEW_REGEX).flatten.first
      return false if related_view_name.blank?
      find { |view| view.name == related_view_name }
    end

    def schema_changed?(exception)
      exception.message =~ DROP_COLUMNS_REGEX ||
      exception.message =~ CHANGE_COLUMNS_REGEX
    end

    def undefined_column?(exception)
      exception.message =~ UNDEFINED_COLUMN_REGEX
    end

    def view_paths
      Dir.glob('db/views/**/*.{sql,sql.erb}').sort
    end
  end
end
