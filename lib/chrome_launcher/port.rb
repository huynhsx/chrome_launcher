# frozen_string_literal: true

require "socket"

module ChromeLauncher
  module Port
    module_function

    DEFAULT_PORT = 9_000

    def free_port
      port = DEFAULT_PORT
      port += 1 until free? port
      port
    end

    def free?(port)
      interfaces.each do |host|
        TCPServer.new(host, port).close
      rescue StandardError
        # skip for error
      end

      true
    rescue SocketError, Errno::EADDRINUSE
      false
    end

    def interfaces
      interfaces = Socket.getaddrinfo("localhost", 8080).map { |e| e[3] }
      interfaces << ["0.0.0.0", ip]

      interfaces.compact.uniq
    end

    # send a UDP packet to Google's DNS server to get the local IP address
    def ip
      original = Socket.do_not_reverse_lookup
      Socket.do_not_reverse_lookup = true

      begin
        UDPSocket.open do |s|
          s.connect "8.8.8.8", 53
          return s.addr.last
        end
      ensure
        Socket.do_not_reverse_lookup = original
      end
    rescue Errno::ENETUNREACH, Errno::EHOSTUNREACH
      # no external ip
    end
  end
end
