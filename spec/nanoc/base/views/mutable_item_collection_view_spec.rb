describe Nanoc::MutableItemCollectionView do
  let(:view_class) { Nanoc::MutableItemView }
  it_behaves_like 'an identifiable collection'
  it_behaves_like 'a mutable identifiable collection'

  let(:config) do
    { string_pattern_type: 'glob' }
  end

  describe '#create' do
    let(:item) do
      Nanoc::Int::Layout.new('content', {}, '/asdf/')
    end

    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config).tap do |coll|
        coll << item
      end
    end

    let(:view) { described_class.new(wrapped, nil) }

    it 'creates an object' do
      view.create('new content', { title: 'New Page' }, '/new/')

      expect(wrapped.size).to eq(2)
      expect(wrapped['/new/'].content.string).to eq('new content')
    end

    it 'returns self' do
      ret = view.create('new content', { title: 'New Page' }, '/new/')
      expect(ret).to equal(view)
    end
  end

  describe '#inspect' do
    let(:wrapped) do
      Nanoc::Int::IdentifiableCollection.new(config)
    end

    let(:view) { described_class.new(wrapped, view_context) }
    let(:view_context) { double(:view_context) }
    let(:config) { { string_pattern_type: 'glob' } }

    subject { view.inspect }

    it { is_expected.to eql('<Nanoc::MutableItemCollectionView>') }
  end
end
