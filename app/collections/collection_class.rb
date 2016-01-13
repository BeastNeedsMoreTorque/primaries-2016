module CollectionClass
  def self.new(plural_id, singular_id, item_class)
    require_relative "../models/#{singular_id}.rb"

    ret = Class.new do
      attr_reader(:plural_id, :singular_id, :item_class)

      @plural_id = plural_id
      @singular_id = singular_id
      @item_class = item_class

      include Enumerable

      attr_reader(:all)

      def initialize(items)
        @all = items
      end

      def each(&block)
        all.each(&block)
      end

      def find(id)
        by_id[id.to_s]
      end

      def find!(id)
        by_id.fetch(id.to_s)
      end

      def include?(id)
        by_id.include?(id.to_s)
      end

      # Creates a Collection of all the given objects.
      #
      # For instance: Candidate.create([[ '1', 'GOP', 'Mr. Foo', 13, 25 ], ...])
      def self.build(database, array_of_param_arrays)
        all = array_of_param_arrays.map { |param_array| @item_class.new(database, *param_array) }
        if @item_class.method_defined?(:<=>)
          all.sort
        end
        self.new(all)
      end

      private

      def by_id
        @by_id ||= all.map{ |i| [ i.id.to_s, i ] }.to_h
      end
    end

    if block_given?
      ret.class_eval(&Proc.new)
    end

    ret
  end
end
