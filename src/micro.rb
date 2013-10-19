#!/usr/bin/env ruby
require './src/rubycompiler'
#require 'debugger'; debugger

def main()
  rc = RubyCompiler.new(ARGV[0])
  rc.compile()
end
main()
