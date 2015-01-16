CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'.'
["#{CONSTRUQT_PATH}/construqt/lib"].each{|path| $LOAD_PATH.unshift(path) }

module Construqt
  @LOGLEVEL=3 #ERROR
end

require("construqt")

module Construqt
  module Flavour
    module Ciscian

      def self.putsResult(result)

        if result.sections
          result.sections.sections.values.each do |section|
            puts section.serialize
          end
        end
      end

      Construqt.log_level(Logger::INFO)

      host=Host.new({"dialect" => ARGV[0]})
      #remove flavour argument
      flavour = ARGV.shift

      oldConfig = []
      while ( line = $stdin.gets )
        oldConfig << line.chomp
      end
      oldResult=Result.new(host)
      oldResult.parse(oldConfig)

      newConfig = []
      while ( line = ARGF.gets )
        newConfig << line
      end
      newResult=Result.new(host)
      newResult.parse(newConfig)

      compareResult=Result.compare(newResult, oldResult)

      puts(compareResult.serialize)

    end
  end
end
