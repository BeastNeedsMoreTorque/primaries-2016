module CollectionClass
  def self.new
    ret = Class.new do
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
