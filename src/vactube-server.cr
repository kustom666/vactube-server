# TODO: Write documentation for `Vactube::Server::Cr`
require "log"
require "file"
require "kemal"
require "./handlers"

module Vactube::Server
  VERSION = "0.1.0"

  # Setup logging
  stdout_backend = ::Log::IOBackend.new
  file_backend = ::Log::IOBackend.new(File.new("./vactube.log", mode: "w"))
  ::Log.builder.bind "*", :warning, stdout_backend
  ::Log.builder.bind "*", :info, file_backend
  Log = ::Log.for("main")

  # Setup Handler
  core_handler = Handlers::CoreHandler.new
  core_handler.start_state

  ws "/" do |socket|
    core_handler.handle_ws socket
  end
  Kemal.run
end
