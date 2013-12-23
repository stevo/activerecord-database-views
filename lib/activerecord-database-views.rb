require 'activerecord-database-views/view'
require 'activerecord-database-views/view_collection'

module ActiveRecord::DatabaseViews
  def self.views
    ViewCollection.new
  end

  def self.without
    views.drop!
    yield if block_given?
    views.load!
  end

  def self.reload!
    ActiveRecord::Base.transaction do
      without
    end
  end
end
