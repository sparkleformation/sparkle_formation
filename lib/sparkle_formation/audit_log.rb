class SparkleFormation
  class AuditLog
    include Enumerable

    class SourcePoint
      attr_reader :line
      attr_reader :path

      def initialize(*args)
        if args.last.is_a?(Hash)
          opts = args.pop.to_smash
        else
          opts = Smash.new
        end
        @path, @line = args
        @path = opts[:path] if opts[:path]
        @line = opts[:line] if opts[:line]
        @line = @line.to_i
        unless @path
          raise ArgumentError,
            "Missing expected value for `path`"
        end
        if !@path.is_a?(String) && !@path.is_a?(Symbol)
          raise TypeError,
            "Expected `String` or `Symbol` for path but received `#{@path.class}`"
        end
      end
    end

    class Record
      # @return [AuditLog]
      attr_reader :audit_log
      # @return [SourcePoint] path and line of location
      attr_reader :location
      # @return [String] name of record
      attr_reader :name
      # @return [Symbol] type of record
      attr_reader :type
      # @return [SourcePoint] path and line of caller
      attr_reader :caller

      def initialize(*args)
        if args.last.is_a?(Hash)
          opts = args.pop.to_smash
        else
          opts = Smash.new
        end
        @name, @type, @location, @caller = args
        @caller = opts[:caller] if opts[:caller]
        @name = opts[:name] if opts[:name]
        @type = opts[:type] if opts[:type]
        @location = opts[:location] if opts[:location]

        [[@name, :name], [@location, :location], [@type, :type], [@caller, :caller]].each do |v, n|
          raise ArgumentError, "Missing required argument `#{n}`" unless v
        end

        @audit_log = AuditLog.new
        @caller = SourcePoint.new(*@caller)
        @location = SourcePoint.new(*@location)
        @type = @type.to_sym
      end
    end

    attr_reader :list

    def initialize
      @list = []
    end

    def <<(item)
      case item
      when Array
        item = Record.new(*item)
      when Hash
        item = Record.new(item)
      end
      add_item(item)
      item
    end

    alias_method :push, :<<

    def each(&block)
      list.each(&block)
    end

    private

    def add_item(item)
      if !item.is_a?(Record)
        raise TypeError, "Expected #{Record.class.name} but " \
              "received #{item.class.name}"
      end
      list.push(item)
    end
  end
end
