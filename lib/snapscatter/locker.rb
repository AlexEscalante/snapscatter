require 'mongo'

module Snapscatter

  class Locker

    def initialize spec
      strategy = spec[:strategy] && spec.delete(:strategy)
      case strategy
      when 'mongo'
        @strategy = MongoLocker.new spec
      else
        @strategy = NoOpLocker.new
      end
    end

    def lock
      @strategy.lock
    end

    def unlock
      @strategy.unlock
    end
  end

  class NoOpLocker
    def method_missing sym
    end
  end

  class MongoLocker
    def initialize spec
      @host = spec[:host] && spec.delete(:host)
      @port = spec[:port] && spec.delete(:port)
      user = spec[:usr] && spec.delete(:usr)
      password = spec[:pwd] && spec.delete(:pwd)

      if @host
        @client = Mongo::MongoClient.new @host, @port, spec # spec contains the options
      else
        @client = Mongo::MongoClient.new
      end

      if user
        @client.add_auth 'admin', user, password, nil
      end
    end

    def lock
      @client.lock!
      say "locked mongo instance at #{@host}"
    end

    def unlock
      @client.unlock!
      say "unlocked mongo instance at #{@host}"
    end
  end

end