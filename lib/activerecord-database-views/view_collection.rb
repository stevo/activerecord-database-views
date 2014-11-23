module ActiveRecord::DatabaseViews
  class ViewCollection
    MISSING_RELATION_REGEX = /relation \"(.*)\" does not exist/
    MISSING_VIEW_REGEX = /view \"(.*)\" does not exist/
    DROP_COLUMNS_REGEX = /cannot drop columns from view/
    CHANGE_COLUMNS_REGEX = /cannot change name of view column \"(.*)\" to \"(.*)\"/

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
      begin
        view.load! and views.delete(view)
      rescue ActiveRecord::StatementInvalid => exception
        if schema_changed?(exception)
          view.drop!
          load_view(view)
        elsif (related_view = retrieve_related_view(exception))
          ActiveRecord::Base.connection.rollback_db_transaction
          load_view(related_view) and retry
        elsif (related_view = retrieve_missing_view(exception))
          ActiveRecord::Base.connection.rollback_db_transaction
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

    def view_paths
      Dir.glob('db/views/**/*.{sql,sql.erb}')
    end
  end
end
