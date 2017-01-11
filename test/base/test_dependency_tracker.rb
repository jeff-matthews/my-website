require 'helper'

class Nanoc::Int::DependencyTrackerTest < Nanoc::TestCase
  def test_initialize
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Verify no dependencies yet
    assert_empty store.objects_causing_outdatedness_of(items[0])
    assert_empty store.objects_causing_outdatedness_of(items[1])
  end

  def test_record_dependency
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
  end

  def test_record_dependency_no_self
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[0])
    store.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
  end

  def test_record_dependency_no_doubles
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[0], items[1])

    # Verify dependencies
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
  end

  def test_objects_causing_outdatedness_of
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[1], items[2])

    # Verify dependencies
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
  end

  def test_store_graph_and_load_graph_simple
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
      Nanoc::Int::Item.new('d', {}, '/d.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[1], items[2])
    store.record_dependency(items[1], items[3])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items[1]],           store.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [items[2], items[3]], store.objects_causing_outdatedness_of(items[1])
    assert_empty store.objects_causing_outdatedness_of(items[2])
    assert_empty store.objects_causing_outdatedness_of(items[3])
  end

  def test_store_graph_and_load_graph_with_removed_items
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
      Nanoc::Int::Item.new('d', {}, '/d.md'),
    ]

    # Create new and old lists
    old_items = [items[0], items[1], items[2], items[3]]
    new_items = [items[0], items[1], items[2]]

    # Create
    store = Nanoc::Int::DependencyStore.new(old_items)

    # Record some dependencies
    store.record_dependency(old_items[0], old_items[1])
    store.record_dependency(old_items[1], old_items[2])
    store.record_dependency(old_items[1], old_items[3])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(new_items)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items[1]],       store.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [items[2], nil],  store.objects_causing_outdatedness_of(items[1])
    assert_empty store.objects_causing_outdatedness_of(items[2])
  end

  def test_store_graph_with_nils_in_dst
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[1], nil)

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
    assert_contains_exactly [nil],      store.objects_causing_outdatedness_of(items[1])
  end

  def test_store_graph_with_nils_in_src
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(nil,      items[2])

    # Store
    store.store
    assert File.file?(store.filename)

    # Re-create
    store = Nanoc::Int::DependencyStore.new(items)

    # Load
    store.load

    # Check loaded graph
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])
    assert_empty store.objects_causing_outdatedness_of(items[1])
  end

  def test_forget_dependencies_for
    # Mock items
    items = [
      Nanoc::Int::Item.new('a', {}, '/a.md'),
      Nanoc::Int::Item.new('b', {}, '/b.md'),
      Nanoc::Int::Item.new('c', {}, '/c.md'),
    ]

    # Create
    store = Nanoc::Int::DependencyStore.new(items)

    # Record some dependencies
    store.record_dependency(items[0], items[1])
    store.record_dependency(items[1], items[2])
    assert_contains_exactly [items[1]], store.objects_causing_outdatedness_of(items[0])

    # Forget dependencies
    store.forget_dependencies_for(items[0])
    assert_empty store.objects_causing_outdatedness_of(items[0])
  end
end
