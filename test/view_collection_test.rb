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

  def test_it_can_property_catch_and_execute_when_a_column_is_undefined
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    ActiveRecord::DatabaseViews::View.any_instance.expects(:load!).raises(ActiveRecord::StatementInvalid, 'column test1 does not exist')
    assert_raises (ActiveRecord::ConnectionNotEstablished) {
      collection.load!
    }
  end

  def test_it_respects_view_exclusion_filter
    ActiveRecord::DatabaseViews.register_view_exclusion_filter( lambda { |name| name == 'sql_a_queries_from_base_view' })
    assert ActiveRecord::DatabaseViews.register_view_exclusion_filter.is_a?(Proc)
    collection = ActiveRecord::DatabaseViews::ViewCollection.new
    assert_equal ['sql_base_view'], collection.collect(&:name)

    ActiveRecord::DatabaseViews.register_view_exclusion_filter(false)
    assert ActiveRecord::DatabaseViews.register_view_exclusion_filter.nil?
  end

end
