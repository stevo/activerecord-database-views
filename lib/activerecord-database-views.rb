require 'activerecord-database-views/view'
require 'activerecord-database-views/view_collection'

module ActiveRecord::DatabaseViews

  def self.register_view_exclusion_filter(proc_handle=nil)
    if proc_handle && proc_handle.respond_to?(:call)
      @view_exclusion_filter = proc_handle
    elsif proc_handle == false
      @view_exclusion_filter = nil
    end
    @view_exclusion_filter
  end

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
