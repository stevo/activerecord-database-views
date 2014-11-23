require File.dirname(__FILE__) + '/test_helper'

class ViewCollectionTests < MiniTest::Test
  def test_it_can_find_sql_files
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    assert_equal 2, collection.views.length
  end

  def test_it_can_properly_catch_and_execute_a_relation_dependency
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    ActiveRecord::DatabaseViews::View.any_instance.expects(:load!).raises(ActiveRecord::StatementInvalid, 'relation "sql_base_view" does not exist')
    assert_raises (ActiveRecord::ConnectionNotEstablished) {
      collection.load!
    }
  end

  def test_it_can_properly_catch_and_execute_a_dependency
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    ActiveRecord::DatabaseViews::View.any_instance.expects(:load!).raises(ActiveRecord::StatementInvalid, 'view "sql_base_view" does not exist')
    assert_raises (ActiveRecord::ConnectionNotEstablished) {
      collection.load!
    }
  end

  def test_it_can_properly_catch_and_execute_when_columns_are_dropped
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    ActiveRecord::DatabaseViews::View.any_instance.expects(:load!).raises(ActiveRecord::StatementInvalid, 'cannot drop columns from view')
    assert_raises (ActiveRecord::ConnectionNotEstablished) {
      collection.load!
    }
  end

  def test_it_can_properly_catch_and_execute_when_columns_are_changed
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    ActiveRecord::DatabaseViews::View.any_instance.expects(:load!).raises(ActiveRecord::StatementInvalid, 'cannot change name of view column "test1" to "test1_full"')
    assert_raises (ActiveRecord::ConnectionNotEstablished) {
      collection.load!
    }
  end
end
