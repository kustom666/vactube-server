require "uuid"
require "msgpack"
require "./payloads"

module Vactube::Handlers
  class CoreHandler
    property connect_chan : Channel(HTTP::WebSocket)
    property disconnect_chan : Channel(HTTP::WebSocket)
    property broadcast_chan : Channel(Tuple(HTTP::WebSocket, Payloads::Message))
    property clients : Hash(HTTP::WebSocket, UUID)
    property channels : Hash(String, String)

    def initialize
      @connect_chan = Channel(HTTP::WebSocket).new
      @disconnect_chan = Channel(HTTP::WebSocket).new
      @broadcast_chan = Channel(Tuple(HTTP::WebSocket, Payloads::Message)).new
      @clients = Hash(HTTP::WebSocket, UUID).new
      @channels = Hash(String, String).new
    end

    def handle_ws(socket : HTTP::WebSocket)
      @connect_chan.send socket

      socket.on_close do
        @disconnect_chan.send socket
      end

      socket.on_ping do |payload|
        socket.pong(payload)
      end

      socket.on_binary do |message|
        unpacked_message = Payloads::Message.from_msgpack(message)
        case unpacked_message.type
        when Payloads::MessageType::Ping
          socket.send Payloads::Message.new(Payloads::MessageType::Pong).to_msgpack
        when Payloads::MessageType::Text
          @broadcast_chan.send({socket, unpacked_message})
        when Payloads::MessageType::Voice
          @broadcast_chan.send({socket, unpacked_message})
        when Payloads::MessageType::Video
          @broadcast_chan.send({socket, unpacked_message})
        when Payloads::MessageType::JoinChannel
          Log.info { "Join Channel unimplemented" }
        when Payloads::MessageType::LeaveChannel
          Log.info { "Leave Channel unimplemented" }
        when Payloads::MessageType::Pong
        end
      end
    end

    def start_state
      spawn do
        loop do
          select
          when client = connect_chan.receive
            client_uuid = UUID.random
            Log.info { "Client connected, creating UUID #{client_uuid}" }
            clients[client] = client_uuid
          when client = disconnect_chan.receive
            Log.info { "Client left #{clients[client]}" }
            clients.delete(client)
          when message = broadcast_chan.receive
            Log.info { "Message received from client #{message[1]}" }
            clients.each do |key, connected|
              if key != message[0]
                Log.info { "Found client to send to" }
                key.send message[1].to_msgpack
              end
            end
          end
        end
      end
    end
  end
end
