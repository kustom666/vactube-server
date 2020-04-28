require "msgpack"

module Vactube::Payloads
  enum MessageType
    Ping         = 0
    Pong         = 1
    JoinChannel  = 2
    LeaveChannel = 3
    Text         = 4
    Voice        = 5
    Video        = 6
  end

  struct Message
    include MessagePack::Serializable

    property type : MessageType
    property payload : Bytes | String | ::Nil

    def initialize(@type, @payload = nil)
    end
  end
end
