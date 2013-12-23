module ActiveRecord::DatabaseViews
  class ViewCollection
    MISSING_RELATION_REGEX = /relation \"(.*)\" does not exist/

    include Enumerable

    attr_reader :views

    def initialize
      @views = view_paths.map { |path| View.new(path) }
    end

    def drop!
      views.each(&:drop!)
    end

    def each
      views.each { |view| yield view }
    end

    def load!
      while views.present?
        load_view(views.first)
      end
    end

    private

    def load_view(view)
      begin
        view.load! and views.delete(view)
      rescue ActiveRecord::StatementInvalid => exc
        if (related_view = retrieve_related_view(exc))
          load_view(related_view)
          retry
        else
          raise exc
        end
      end
    end

    def retrieve_related_view(exception)
      related_view_name = exception.message.scan(MISSING_RELATION_REGEX).flatten.first
      return false if related_view_name.blank?
      find { |view| view.name == related_view_name }
    end

    def view_paths
      Dir.glob("db/views/**/*.sql")
    end
  end
end
