#!/usr/bin/env ruby
require './src/rubycompiler'
#require 'debugger'; debugger

def main()
  begin
    infile = File.new(ARGV[0], "r")
    rc = RubyCompiler.new
    rc.createParseTable()
    infile.each_line {|line|
      cleanline = (line.include?('--')? line[0,line.index('--')] : line)
      cleanline.lstrip! 
      tokens = rc.tokenizeLine(cleanline)
      tokens.each{|tok|
        token = tok[1] =~ Grammar::TERMINALS ? tok[1] : tok[0]
        rc.addToStack(tok)
        error,reply = rc.processSingleToken(token.strip)
        if error == 1
          puts "Not Accepted"
          exit
        end
      }
    }
    rc.printSymbolStack
  rescue
  ensure
    infile.close unless infile.nil?
  end
end
main()
