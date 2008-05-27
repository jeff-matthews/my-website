require 'helper'

class Nanoc::PageTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestDataSource

    attr_reader :save_called, :move_called, :delete_called, :was_loaded

    def initialize
      @save_called    = false
      @move_called    = false
      @delete_called  = false
      @references     = 0
      @was_loaded     = false
    end

    def save_page(page)
      @save_called = true
    end

    def move_page(page, new_path)
      @move_called = true
    end

    def delete_page(page)
      @delete_called = true
    end

    def loading
      # Load if necessary
      up if @references == 0
      @references += 1

      yield
    ensure
      # Unload if necessary
      @references -= 1
      down if @references == 0
    end

    def up
      @was_loaded = true
    end

    def down
    end
  end

  class TestSite

    def data_source
      @data_source ||= TestDataSource.new
    end

  end

  def test_initialize
    # Make sure attributes are cleaned
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Make sure path is fixed
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, 'foo')
    assert_equal('/foo/', page.path)
  end

  def test_to_proxy
    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    assert_equal({ :foo => 'bar' }, page.attributes)

    # Create proxy
    page_proxy = page.to_proxy

    # Check values
    assert_equal('bar', page_proxy.foo)
  end

  def test_modified
    # TODO implement
  end

  def test_created
    # TODO implement
  end

  def test_outdated
    # TODO implement
  end

  def test_attribute_named
    # Create site
    site = Nanoc::Site.new({})

    # Create page defaults (hacky...)
    page_defaults = Nanoc::PageDefaults.new({ :quux => 'stfu' })
    site.instance_eval { @page_defaults = page_defaults }

    # Create page
    page = Nanoc::Page.new("content", { 'foo' => 'bar' }, '/foo/')
    page.site = site

    # Test
    assert_equal('bar',  page.attribute_named(:foo))
    assert_equal('html', page.attribute_named(:extension))
    assert_equal('stfu', page.attribute_named(:quux))

    # Create page
    page = Nanoc::Page.new("content", { 'extension' => 'php' }, '/foo/')
    page.site = site

    # Test
    assert_equal(nil,    page.attribute_named(:foo))
    assert_equal('php',  page.attribute_named(:extension))
    assert_equal('stfu', page.attribute_named(:quux))
  end

  def test_content
    # TODO implement
  end

  def test_layout
    # TODO implement
  end

  def test_disk_path
    # TODO implement
  end

  def test_web_path
    # TODO implement
  end

  def test_save
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes'}, '/path/')
    page.site = site

    # Save
    assert(!site.data_source.save_called)
    assert(!site.data_source.was_loaded)
    page.save
    assert(site.data_source.save_called)
    assert(site.data_source.was_loaded)
  end

  def test_move_to
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes'}, '/path/')
    page.site = site

    # Move
    assert(!site.data_source.move_called)
    assert(!site.data_source.was_loaded)
    page.move_to('/new_path/')
    assert(site.data_source.move_called)
    assert(site.data_source.was_loaded)
  end

  def test_delete
    # Create site
    site = TestSite.new

    # Create page
    page = Nanoc::Page.new("content", { :attr => 'ibutes'}, '/path/')
    page.site = site

    # Delete
    assert(!site.data_source.delete_called)
    assert(!site.data_source.was_loaded)
    page.delete
    assert(site.data_source.delete_called)
    assert(site.data_source.was_loaded)
  end

  def test_compile
    # TODO implement
  end

  def test_do_filter
    # TODO implement
  end

  def test_do_filter_outdated
    # Create page
    page = Nanoc::Page.new("content", { :filters => [ 'asdf' ] }, '/path/')

    # Filter
    assert_raise Nanoc::Errors::NoLongerSupportedError do
      page.instance_eval { filter!(:pre) }
    end
  end

  def test_do_layout
    # TODO implement
  end

end
