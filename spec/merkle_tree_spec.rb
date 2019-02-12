# frozen_string_literal: true

require 'merkle_tree'

RSpec.describe 'Merkle Tree' do
  it 'exists' do
    expect(MerkleTree.new).to be
  end

  context 'given a tree' do
    before(:each) do
      @tree = MerkleTree.new
    end

    it 'defaults to an empty Array of leaves' do
      expect(@tree.leaves).to be_empty
    end

    it 'has a nil root if it has no leaves' do
      expect(@tree.root).to be_nil
    end

    it 'can add a leaf' do
      expect(@tree.add(7)).to eq(@tree.root)
    end

    it 'can add multiple leaves via an Array' do
      root = @tree.add([7, 8, 9, 10])
      expect(root).to eq(@tree.root)
      expect(@tree.leaves.length).to eq(4)
      expect(@tree.root).to eq(16847699529906527489)
    end

    it 'can add multiple leaves via args' do
      expect(@tree.add(7, 8, 9, 10)).to eq(@tree.root)
      expect(@tree.leaves.length).to eq(4)
      expect(@tree.root).to eq(16847699529906527489)
    end

    it 'can add an odd number of leaves' do
      expect(@tree.add(7, 8, 9, 10, 12)).to eq(@tree.root)
      expect(@tree.leaves.length).to eq(5)
      expect(@tree.root).to eq(17063019478491036856)
    end

    it 'can add an empty array' do
      expect(@tree.add([])).to eq(@tree.root)
    end

    context 'when a leaf is added' do
      before(:each) do
        @tree.add(7)
      end

      it 'has a non-nil root' do
        expect(@tree.root).not_to be_nil
      end

      it 'has a non-empty array of leaves' do
        expect(@tree.leaves).not_to be_empty
      end

      it 'can add anther leaf' do
        old_root = @tree.root
        new_root = @tree.add(8)
        expect(@tree.root).not_to eq(old_root)
        expect(@tree.root).not_to be_nil
        expect(@tree.root).to eq(new_root)
      end

      it 'raises an exception when calling for that single leaf (which is also the root)' do
        expect(@tree.path(7)).to eq([])
      end

      it 'can add an empty array' do
        expect(@tree.add([])).to eq(@tree.root)
      end
    end

    context 'with lots of leaves' do
      before(:each) do
        @tree.add(33, 44, 55, 66, 12, 34, 123, 543, 8748)
      end

      it 'has a path to the root' do
        expected = [826817707225688321, 4931992387027573400, 5286759298248796023, 5922258105097092295]
        actual = @tree.path(44)
        expect(actual).to match_array(expected)
      end

      it 'can add an empty array' do
        expect(@tree.add([])).to eq(@tree.root)
      end

      context 'given a path to root' do
        before(:each) do
          @path = @tree.path(44)
        end

        it 'can verify the path to root' do
          expect(MerkleTree.verify(44, @path, @tree.root)).to be_truthy
        end

        it 'can verify that a value/path is not part of the tree' do
          expect(MerkleTree.verify(55, @path, @tree.root)).to be_falsey
        end
      end
    end
  end
end
