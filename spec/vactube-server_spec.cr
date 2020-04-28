require "./spec_helper"

describe "Vactube::Server" do
  it "answers ping with pong" do
    ping_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Ping)
    pong_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Pong)
    ws = HTTP::WebSocket.new("127.0.0.1", "/", 3000)

    ws.on_binary do |message_bytes|
      message_bytes.should_not eq(pong_message.to_msgpack)
      ws.close
    end

    ws.send ping_message.to_msgpack
    ws.run
  end
end
