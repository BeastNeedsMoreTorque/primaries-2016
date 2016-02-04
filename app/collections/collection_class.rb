module CollectionClass
  def self.new(plural_id, singular_id, item_class)
    ret = Class.new do
      attr_reader(:plural_id, :singular_id, :item_class)

      @plural_id = plural_id
      @singular_id = singular_id
      @item_class = item_class

      include Enumerable

      attr_reader(:all)

      def initialize(items)
        @all = items
        @by_id = @all.each_with_object({}) { |i, h| h[i.id] = i }
      end

      def each(&block)
        @all.each(&block)
      end

      def find(id)
        @by_id[id.to_s]
      end

      def find!(id)
        @by_id.fetch(id.to_s)
      end

      def include?(id)
        @by_id.include?(id.to_s)
      end
    end

    if block_given?
      ret.class_eval(&Proc.new)
    end

    ret
  end
end
