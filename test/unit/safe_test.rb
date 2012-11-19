require 'test_helper'

class WriteConcernTest < Test::Unit::TestCase

  context "Write-Concern modes on Mongo::Connection " do
    setup do
      @safe_value = {:w => 7, :j => false, :fsync => false, :wtimeout => false}
      @client = Mongo::Connection.new('localhost', 27017, :safe => @safe_value, :connect => false)
    end

    should "propogate to DB" do
      db = @client['foo']
      assert_equal @safe_value[:w], db.write_concern[:w]


      db = @client.db('foo')
      assert_equal @safe_value[:w], db.write_concern[:w]

      db = DB.new('foo', @client)
      assert_equal @safe_value[:w], db.write_concern[:w]
    end

    should "allow db override" do
      db = DB.new('foo', @client, :safe => false)
      assert_equal 0, db.write_concern[:w]

      db = @client.db('foo', :safe => false)
      assert_equal 0, db.write_concern[:w]
    end

    context "on DB: " do
      setup do
        @db = @client['foo']
      end

      should "propogate to collection" do
        col = @db.collection('bar')
        assert_equal @safe_value, col.write_concern

        col = @db['bar']
        assert_equal @safe_value, col.write_concern

        col = Collection.new('bar', @db)
        assert_equal @safe_value, col.write_concern
      end

      should "allow override on collection" do
        col = @db.collection('bar', :safe => false)
        assert_equal 0, col.write_concern[:w]

        col = Collection.new('bar', @db, :safe => false)
        assert_equal 0, col.write_concern[:w]
      end
    end

    context "on operations supporting safe mode" do
      setup do
        @col = @client['foo']['bar']
      end

      should "use default value on insert" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == @safe_value
        end

        @col.insert({:a => 1})
      end

      should "allow override alternate value on insert" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == {:w => 100, :j => false, :fsync => false, :wtimeout => false}
        end

        @col.insert({:a => 1}, :safe => {:w => 100})
      end

      should "allow override to disable on insert" do
        @client.expects(:send_message)
        @col.insert({:a => 1}, :safe => false)
      end

      should "use default value on update" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == @safe_value
        end

        @col.update({:a => 1}, {:a => 2})
      end

      should "allow override alternate value on update" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == {:w => 100, :j => false, :fsync => false, :wtimeout => false}
        end

        @col.update({:a => 1}, {:a => 2}, :safe => {:w => 100})
      end

      should "allow override to disable on update" do
        @client.expects(:send_message)
        @col.update({:a => 1}, {:a => 2}, :safe => false)
      end

      should "use default value on remove" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == @safe_value
        end

        @col.remove
      end

      should "allow override alternate value on remove" do
        @client.expects(:send_message_with_gle).with do |op, msg, log, n, safe|
          safe == {:w => 100, :j => false, :fsync => false, :wtimeout => false}
        end

        @col.remove({}, :safe => {:w => 100})
      end

      should "allow override to disable on remove" do
        @client.expects(:send_message)
        @col.remove({}, :safe => false)
      end
    end
  end
end