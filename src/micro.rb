#!/usr/bin/env ruby
require './src/grammar'

def main()
  infile = File.new(ARGV[0], "r")
  parseStack = Grammar::DEFINITIONS["program"].split

  infile.each_line {|line|
    cleanline = (line.include?('--')? line[0..line.index('--')-1] : line)
    cleanline.lstrip! 
    tokens = tokenizeLine(cleanline)
    tokens.each{|tok|
      # tok[0] info
      # tok[1] value
      puts "#{tok[0]}: #{tok[1]}"
      cur = parseStack[0]
      valid, parseStack = processSingleToken(parseStack, tok)
      if valid
        puts "tok[0]} has passed"
      else
        puts "tok[0]} did not pass"
      end
    }
  }
  infile.close
end

def tokenizeLine(cleanline)
  currFront,i = 0,0
  found=false
  tokens = []
  while i < cleanline.length
    found = false
    if !(cleanline[i] =~ (Grammar::SINGLEOP)).nil?
      basetok = cleanline[currFront..i-1]

      if !(basetok =~ /^;/).nil?
        tokens << [ "OPERATOR", ";" ]
        break
      end
      if (cleanline[i] =~ /"|'/).nil?
        if !(basetok.strip =~ (Grammar::KEYWORD)).nil?
          tokens << [ "KEYWORD", "#{basetok.strip}" ]
          found = true
        elsif (basetok.strip =~ (Grammar::OPERATOR)).nil?
          if !(basetok.strip =~ (Grammar::INTLITERAL)).nil?
            tokens << [ "INTLITERAL", "#{basetok.strip}" ]
          elsif !(basetok.strip =~ (Grammar::FLOATLITERAL)).nil?
            tokens << [ "FLOATLITERAL", "#{basetok.strip}" ]
          else
            tokens << [ "IDENTIFIER", "#{basetok.strip}" ] if basetok.strip.length > 0

          end
          found = true
        end
        if cleanline[i] != ' '
          if !(cleanline[i..i+1] =~ (Grammar::OPERATOR)).nil?
            tokens << ["OPERATOR" , "#{cleanline[i..i+1]}"]
            i += 1
          elsif !(cleanline[i] =~ (Grammar::OPERATOR)).nil? 
            tokens << ["OPERATOR", "#{cleanline[i]}"]
          end
          found = true
        end
      else
        endQuo = cleanline.index(/'|"/,i+1)
        tokens << [ "STRINGLITERAL", "#{cleanline[i..endQuo]}"]
        i = endQuo
        found = true
      end
    end
    i += 1 
    if found
      currFront = i
    end
  end
  tokens
end

def createParseTable()
  parseTable = {}
  Grammar::DEFINITIONS.each{|symbol, interp|
    Grammar::TERMINALS_LIST.each{|term|
      parseTable[symbol]={term => 0}
    }
  }
  firstset={}
  Grammar::DEFINITIONS.each{|symbol, interp|
    firstSet[symbol] = getFirstSet(symbol, symbol)
  }
  followset={}
  Grammar::DEFINITIONS.each{|symbol, interp|
    choices = interp.split('|')
    choices.each{|choice|
      tokens = choice.split
      tokens.each{|tok|

      }
    }
  }

end
def getFirstSet(topsymbol, symbol)
  choices = Grammar::DEFINITIONS[symbol].split('|')
  choices.each{|choice|
    tokens = choice.split(' ')
    if Grammar::DEFINITIONS.include?(tokens[0])
      firstset + getFirstSet(topsymbol,tokens[0])
    else
      return [tokens[0]]
    end
  }
  return firstset
end
def getFollowSet(topsymbol, symbol)
end
# parseStack, the current stack string we are looking at
# token, (token[0] info:token[1] value)
def processSingleToken(parseStack, token)
  return false if parseStack.size > 10
  popped = parseStack.shift
  currStackState = parseStack
  result = false
  if ( popped =~ Grammar::TERMINAL or popped =~ Grammar::DESCRIBERS)
    # If the grammar isn't literal, then it must match a keyword or operation verbosely; token[1]
    # if the grammar is literal, then it only need to match the token type; token[0]
    puts "#{popped} TERMINAL"
    return ( (!(Grammar::DESCRIBERS =~ popped) and ( popped == token[1] ) ) or ( (Grammar::DESCRIBERS =~ popped) and token[0] == popped) ), parseStack
  else
    # for each of the choices (in an OR situation), split, and decide
    puts "#{popped} -> #{token[1]}"
    choices = Grammar::DEFINITIONS[popped].split('|')
    choices[-1] = "" if choices[-1] == "empty"
    # if one of the pieces is matched in the newly generated string, choose that path over others.
    if (choices.index(token[0]).nil? == false or choices.index(token[1]).nil? == false)
      expr = choices[choices.index(token[0]).nil? ? choices.index(token[1]) : choices.index(token[0])]
      parseStack = currStackState
      expr_tokens = expr.split(' ')
      expr_tokens.each { |expr_tok|
        parseStack.unshift expr_tok
      }
      result,parseStack = processSingleToken(parseStack, token)
    else
      # all else fails, brute force
      choices.each { |expr|
        parseStack = currStackState
        expr_tokens = expr.split(' ')
        expr_tokens = (expr_tokens << parseStack).flatten
        result, parseStack = processSingleToken(expr_tokens, token)
        return [result, parseStack] if result
      }
    end
  end
  return result,parseStack
end

main()
