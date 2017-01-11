describe Nanoc::Int::OutdatednessChecker do
  let(:outdatedness_checker) do
    described_class.new(
      site: site,
      checksum_store: checksum_store,
      dependency_store: dependency_store,
      rule_memory_store: rule_memory_store,
      action_provider: action_provider,
      reps: reps,
    )
  end

  let(:checksum_store) { double(:checksum_store) }

  let(:dependency_store) do
    Nanoc::Int::DependencyStore.new(objects)
  end

  let(:objects) { [item] }

  let(:site) do
    Nanoc::Int::Site.new(
      config: config,
      items: [],
      layouts: [],
      code_snippets: [],
    )
  end

  let(:rule_memory_store) do
    Nanoc::Int::RuleMemoryStore.new
  end

  let(:old_memory_for_item_rep) do
    Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
      mem.add_filter(:erb, {})
    end
  end

  let(:new_memory_for_item_rep) { old_memory_for_item_rep }

  let(:action_provider) { double(:action_provider) }

  let(:reps) do
    Nanoc::Int::ItemRepRepo.new
  end

  let(:item_rep) { Nanoc::Int::ItemRep.new(item, :default) }
  let(:item) { Nanoc::Int::Item.new('stuff', {}, '/foo.md') }

  let(:objects) { [item] }

  before do
    reps << item_rep
    rule_memory_store[item_rep] = old_memory_for_item_rep.serialize

    allow(action_provider).to receive(:memory_for).with(item_rep).and_return(new_memory_for_item_rep)
  end

  describe '#basic_outdatedness_reason_for' do
    subject { outdatedness_checker.send(:basic_outdatedness_reason_for, obj) }

    let(:checksum_store) { Nanoc::Int::ChecksumStore.new(objects: objects) }

    let(:config) { Nanoc::Int::Configuration.new }

    before do
      checksum_store.add(item)

      allow(site).to receive(:code_snippets).and_return([])
      allow(site).to receive(:config).and_return(config)
    end

    context 'with item' do
      let(:obj) { item }

      context 'rule memory differs' do
        let(:new_memory_for_item_rep) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Int::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with item rep' do
      let(:obj) { item_rep }

      context 'rule memory differs' do
        let(:new_memory_for_item_rep) do
          Nanoc::Int::RuleMemory.new(item_rep).tap do |mem|
            mem.add_filter(:super_erb, {})
          end
        end

        it 'is outdated due to rule differences' do
          expect(subject).to eql(Nanoc::Int::OutdatednessReasons::RulesModified)
        end
      end

      # …
    end

    context 'with layout' do
      # …
    end
  end

  describe '#outdated_due_to_dependencies?' do
    subject { outdatedness_checker.send(:outdated_due_to_dependencies?, item) }

    let(:checksum_store) { Nanoc::Int::ChecksumStore.new(objects: objects) }

    let(:other_item) { Nanoc::Int::Item.new('other stuff', {}, '/other.md') }
    let(:other_item_rep) { Nanoc::Int::ItemRep.new(other_item, :default) }

    let(:config) { Nanoc::Int::Configuration.new }

    let(:objects) { [item, other_item] }

    let(:old_memory_for_other_item_rep) do
      Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
        mem.add_filter(:erb, {})
      end
    end

    let(:new_memory_for_other_item_rep) { old_memory_for_other_item_rep }

    before do
      reps << other_item_rep
      rule_memory_store[other_item_rep] = old_memory_for_other_item_rep.serialize
      checksum_store.add(item)
      checksum_store.add(other_item)
      checksum_store.add(config)

      allow(action_provider).to receive(:memory_for).with(other_item_rep).and_return(new_memory_for_other_item_rep)
      allow(site).to receive(:code_snippets).and_return([])
      allow(site).to receive(:config).and_return(config)
    end

    context 'transitive dependency' do
      let(:distant_item) { Nanoc::Int::Item.new('distant stuff', {}, '/distant.md') }
      let(:distant_item_rep) { Nanoc::Int::ItemRep.new(distant_item, :default) }

      before do
        reps << distant_item_rep
        checksum_store.add(distant_item)
        rule_memory_store[distant_item_rep] = old_memory_for_other_item_rep.serialize
        allow(action_provider).to receive(:memory_for).with(distant_item_rep).and_return(new_memory_for_other_item_rep)
      end

      context 'on attribute + attribute' do
        before do
          dependency_store.record_dependency(item, other_item, attributes: true)
          dependency_store.record_dependency(other_item, distant_item, attributes: true)
        end

        context 'distant attribute changed' do
          before { distant_item.attributes[:title] = 'omg new title' }

          it 'has correct outdatedness of item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).not_to be
          end

          it 'has correct outdatedness of other item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be
          end
        end

        context 'distant raw content changed' do
          before { distant_item.content = Nanoc::Int::TextualContent.new('omg new content') }

          it 'has correct outdatedness of item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).not_to be
          end

          it 'has correct outdatedness of other item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).not_to be
          end
        end
      end

      context 'on compiled content + attribute' do
        before do
          dependency_store.record_dependency(item, other_item, compiled_content: true)
          dependency_store.record_dependency(other_item, distant_item, attributes: true)
        end

        context 'distant attribute changed' do
          before { distant_item.attributes[:title] = 'omg new title' }

          it 'has correct outdatedness of item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).to be
          end

          it 'has correct outdatedness of other item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).to be
          end
        end

        context 'distant raw content changed' do
          before { distant_item.content = Nanoc::Int::TextualContent.new('omg new content') }

          it 'has correct outdatedness of item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, item)).not_to be
          end

          it 'has correct outdatedness of other item' do
            expect(outdatedness_checker.send(:outdated_due_to_dependencies?, other_item)).not_to be
          end
        end
      end
    end

    context 'only attribute dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.not_to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'only raw content dependency' do
      before do
        dependency_store.record_dependency(item, other_item, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.not_to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'only path dependency' do
      before do
        dependency_store.record_dependency(item, other_item, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.not_to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'path changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_snapshot(:donkey, '/giraffe.txt')
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'attribute + raw content dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true, raw_content: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'attribute + raw content changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.to be }
      end

      context 'rules changed' do
        let(:new_memory_for_other_item_rep) do
          Nanoc::Int::RuleMemory.new(other_item_rep).tap do |mem|
            mem.add_filter(:erb, {})
            mem.add_filter(:donkey, {})
          end
        end

        it { is_expected.not_to be }
      end
    end

    context 'attribute + other dependency' do
      before do
        dependency_store.record_dependency(item, other_item, attributes: true, path: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.not_to be }
      end
    end

    context 'other dependency' do
      before do
        dependency_store.record_dependency(item, other_item, path: true)
      end

      context 'attribute changed' do
        before { other_item.attributes[:title] = 'omg new title' }
        it { is_expected.not_to be }
      end

      context 'raw content changed' do
        before { other_item.content = Nanoc::Int::TextualContent.new('omg new content') }
        it { is_expected.not_to be }
      end
    end
  end
end
