require "log"
require "http"
require "msgpack"
require "ncurses"

require "../src/payloads"

module Vactube::CliClient
  file_backend = ::Log::IOBackend.new(File.new("./vactube-client.log", mode: "w"))
  ::Log.builder.bind "*", :info, file_backend
  Log = ::Log.for("cli-client")

  NCurses.start
  NCurses.cbreak
  NCurses.no_echo
  win_messages = NCurses::Window.new(NCurses.height - 3, NCurses.width - 2, 1, 1)
  win_messages_border = NCurses::Window.new(NCurses.height - 1, NCurses.width, 0, 0)
  win_input = NCurses::Window.new(1, NCurses.width, NCurses.height - 1, 0)
  win_messages_border.border
  win_messages_border.refresh
  win_messages.scrollok
  win_messages.print("Connecting to the server", win_messages.height/2, win_messages.width/2)
  win_messages.refresh

  win_input.keypad(true)
  win_input.refresh

  # if NCurses.has_colors?
  #   NCurses.init_color_pair(1, NCurses::Color::Black, NCurses::Color::White)
  #   NCurses.change_color(NCurses::Color::Black, 150, 146, 175)
  #   NCurses.set_color 1
  # else
  #   Log.warn { "Terminal doesn't support colors" }
  # end

  ping_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Ping)
  pong_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Pong)
  text_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Text, "Coucou tu veux voir ma bite".byte_slice(0))
  voice_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Voice, "".byte_slice(0))
  video_message = Vactube::Payloads::Message.new(Vactube::Payloads::MessageType::Video, "".byte_slice(0))
  messages_history = Array(String).new

  ws = HTTP::WebSocket.new("127.0.0.1", "/", 3000)

  ws.on_message do |message|
    Log.info { "got a text message in binary mode" }
  end

  ws.on_binary do |message_bytes|
    unpacked_message = Vactube::Payloads::Message.from_msgpack message_bytes
    Log.info { "UNPACKED MESSAGE: #{unpacked_message}" }
    if unpacked_message.type == Vactube::Payloads::MessageType::Text
      win_messages.print("#{unpacked_message.payload.to_s}\n")
      win_messages.refresh
    end
  end

  spawn do
    ws.run
  end

  win_messages.clear
  win_messages.refresh
  input_buffer = Array(String).new
  win_input.get_char do |ch|
    if ch == '\n'
      message = String.build do |str|
        input_buffer.each do |buff_ch|
          str << buff_ch
        end
      end
      text_message.payload = message
      ws.send text_message.to_msgpack
      input_buffer.clear
      win_messages.print("#{message}\n")
    elsif ch == NCurses::Key::Backspace
      input_buffer.pop if input_buffer.size > 0
    else
      input_buffer.push ch.to_s
    end

    message = String.build do |str|
      input_buffer.each do |buff_ch|
        str << buff_ch
      end
    end

    win_input.clear
    win_input.print message
    win_messages.refresh
    win_input.refresh
  end

  NCurses.end
end
