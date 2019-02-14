# frozen_string_literal: true

require 'ruby-xxhash'

# Implementation of a Merkle tree
# This implementation is for exploring the details of the data structure
# It is not meant to be a servicable production library
# A non-cryptographically secure library is used for creating the hashes
# it has the benefit of being extremely fast, at the expense of security
# which is just fine for non-production use.
#
# @author Nathan Menge
# @attr_reader [Integer] root The root of the Merkle tree
# @attr_reader [Array] leaves An array containing all of the leaf nodes of the tree
class MerkleTree
  attr_reader :root, :leaves

  DEFAULT_HASH_METHOD = XXhash.method(:xxh64)

  # Constructor
  # @param [Array] leaves Takes an optional Array of values to add to the tree
  # @return [Integer, nil] Returns the value of the root node
  def initialize(leaves = [], hash_method: DEFAULT_HASH_METHOD)
    @leaves = leaves
    @history = {}
    @partners = {}
    @hash_method = hash_method
    @root = build(@leaves)
  end

  # Adds values to the tree
  # @param [Array, #to_s] *values Can take any number of #to_s-able objects either as arguments and/or as an array
  # @return [Integer, nil] Returns the root node value
  def add(*values)
    keys = values.flatten.map do |value|
      key = create_hash(value)
      @history[value] = key
    end
    @leaves.concat(keys)
    @root = build(@leaves)
  end

  # Finds the path from value to root in a built Merkle tree
  # @param [#to_s] value A value to start from
  # @return [Array] Returns an array of hashes that represent the complementary values to reach the root
  def path(value)
    result = create_hash(value)
    tree_path = []
    until result == @root
      raise(ArgumentError, 'Value is not part of this tree') unless @partners.key?(result)

      partner = @partners[result]
      tree_path << partner
      result = self.class.hash_parents(result, partner)
    end
    tree_path
  end

  private

  # Builds the merkle tree by joining keys and hashing them
  # @param [Array] leaves Takes an array of Integers(hash strings) that represent all the leaves to the tree
  # @return [Integer, nil] Returns the root key
  def build(leaves)
    return nil if leaves.empty?

    branches = leaves.dup
    branches << hash_parents(*branches.slice!(0, 2)) until branches.length == 1
    branches.first
  end

  # Creates a key from a value
  # @param [#to_s] value Takes a value to hash to a key
  # @return [Integer] Returns a hashed value
  def create_hash(value)
    value = value.to_s unless value.respond_to?(:downcase)
    key = self.class.create_hash(value, hash_method: @hash_method)
    @history[value] = key
  end

  # Creates a key from parent keys
  # @param [Array, #to_s] *parents Takes either an Array and/or any number of arguments of to_s-able values
  # @return [Integer] Returns a hashed value
  def hash_parents(*parents)
    @partners[parents.first] = parents.last
    @partners[parents.last] = parents.first
    create_hash(self.class.parent_hash_string(parents))
  end

  # This method handles the actual hashing of values
  # @param [#to_s] value A value to hash
  # @param [#call] hash_method A method to use to create a hash
  def self.create_hash(value, hash_method: DEFAULT_HASH_METHOD)
    hash_method.call(value.to_s)
  end

  def self.hash_parents(*parents, hash_method: DEFAULT_HASH_METHOD)
    create_hash(parent_hash_string(parents), hash_method: hash_method)
  end

  def self.parent_hash_string(*parents)
    parents.flatten.map(&:to_s).sort.join('')
  end

  # This method will verify that a given value and path to root, actually reaches the root node
  # @param [#to_s] value Value for which inclusion in the tree will be verified
  # @param [Array] path An array of complementary hash values that should lead to the root node
  # @param [#to_s] root Root value to verify inclusion of the value param along the given path
  # @return [true, false] Returns a boolean value true for value is part of root, false for not
  def self.verify(value, path, root, hash_method: DEFAULT_HASH_METHOD)
    root == path.reduce(create_hash(value, hash_method: hash_method)) do |acc, node|
      hash_parents(acc, node, hash_method: hash_method)
    end
  end
end
