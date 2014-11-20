require File.dirname(__FILE__) + '/test_helper'

class ViewCollectionTests < MiniTest::Test
  def test_it_can_find_sql_files
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    assert_equal 2, collection.views.length
  end
end
