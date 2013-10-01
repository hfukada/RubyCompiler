#!/usr/bin/env ruby
require './src/rubycompiler'
#require 'debugger'; debugger

def main()
  begin
    infile = File.new(ARGV[0], "r")
    rc = RubyCompiler.new
    rc.createParseTable()
    lastImportant = ''
    infile.each_line {|line|
      ignoreLine = 1
      doDecls = 1
      cleanline = (line.include?('--')? line[0,line.index('--')] : line)
      cleanline.lstrip! 

      tokens = rc.tokenizeLine(cleanline)

      if !tokens.empty? and tokens[0][1] =~ /^(FUNCTION|INT|FLOAT|STRING|IF|ELSIF|ENDIF|DO|WHILE|END)$/
        ignoreLine = 0
        if tokens[0][1] =~ /^(IF|ELSIF|ENDIF|DO|WHILE|END)$/
          doDecls = 0
        end
      end

      tokens.each{|tok|
        declError = 0
        token = tok[1] =~ Grammar::TERMINALS ? tok[1] : tok[0]
        error,reply = rc.processSingleToken(token.strip)
        if ignoreLine == 0
          declError = rc.addToStack(tok, doDecls)
        end
        if error == 1
          puts "Not Accepted"
          exit
        end
        if declError == 1
          print "DECLARATION ERROR #{tok[1]}\r\n"
          exit
        end
      }
    }
    rc.printSymbolTable
  ensure
    infile.close unless infile.nil?
  end
end
main()
