#!/usr/bin/env ruby
require './src/grammar'
#require 'debugger'; debugger

def main()
  infile = File.new(ARGV[0], "r")
  rc = RubyCompiler.new
  rc.createParseTable()
  infile.each_line {|line|
    cleanline = (line.include?('--')? line[0..line.index('--')-1] : line)
    cleanline.lstrip! 
    puts "cleanline: #{cleanline}"
    tokens = rc.tokenizeLine(cleanline)
    tokens.each{|tok|
      # tok[0] info
      # tok[1] value
      #puts "#{tok[0]}: #{tok[1]}"
      #cur = parseStack[0]
      tok = tok[1] =~ Grammar::TERMINALS ? tok[1] : tok[0]
      valid = rc.processSingleToken(tok.strip)
      #if vali
      #  puts "tok[0]} has passed"
      #else
      #  puts "tok[0]} did not pass"
      #end
    }
  }
  infile.close
end

class RubyCompiler
  @parseStack
  @parseTable
  @indexedGrammar

  def initialize
    @parseStack = Grammar::DEFINITIONS["program"].split 
    @parseTable = {}
    @indexedGrammar = []
  end

  # method to tokenize a line
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
    firstSet={}
    Grammar::DEFINITIONS.each{|symbol, interp|
      @parseTable[symbol] ={}
      firstSet[symbol] = getFirstSet(symbol,[symbol]).uniq
      puts "First(#{symbol}) = #{firstSet[symbol]}"
    }
    followSet={}
    Grammar::DEFINITIONS.each{|symbol, interp|
      followSet[symbol] = getFollowSet(firstSet,symbol,[symbol]).uniq
      puts "Follow(#{symbol}) = #{followSet[symbol]}"
    }
    Grammar::DEFINITIONS.each{|symbol, interp|
      interp.split('|').each{|choice|
        @indexedGrammar.push({:symbol => symbol, :interp=>choice, :firstSet => firstSet[symbol], :followSet => followSet[symbol] })
      }
    }
    (0..@indexedGrammar.size-1).each{|i|
      symbol = @indexedGrammar[i][:symbol]
      interp = @indexedGrammar[i][:interp]
      firstSeti = @indexedGrammar[i][:firstSet]
      followSeti = @indexedGrammar[i][:followSet]
     # @indexedGrammar[i][:firstSet].each{|tok|
     #   puts "#{symbol} x #{tok} -> #{i}| #{interp}"
     #   @parseTable[symbol][tok] = @parseTable[symbol][tok].nil? ? i : @parseTable[symbol][tok]
     # }

      tokens = interp.split
      if interp == "empty"
        if @indexedGrammar[i][:followSet] != nil
          @indexedGrammar[i][:followSet].each{|tok|
            @parseTable[symbol][tok] = @parseTable[symbol][tok].nil? ? i : @parseTable[symbol][tok]
          }
        end
      else
        if !firstSet[tokens[0]].nil?
          firstSet[tokens[0]].each{|tok|
            #puts "#{symbol} x #{tok} -> #{i}| #{interp}"
            @parseTable[symbol][tok] = i
          }
        else
          #puts "#{symbol} x #{firstSet[tokens[0]]} -> #{i}| #{interp}"
          @parseTable[symbol][tokens[0]] = i
        end
       # firstSet[tokens[0]].each{|tok|
       #   if Grammar::TERMINAL_LIST.include?(tokens[0])
       #     puts "specify"
       #     puts "#{symbol} x #{tokens[0]} -> #{i}| #{interp}"
       #     @parseTable[symbol][tokens[0]] = i
       #   elsif @indexedGrammar[i][:firstSet].include?(tok)
       #     puts "specify"
       #     puts "#{symbol} x #{tokens[0]} -> #{i}| #{interp}"
       #     @parseTable[symbol][tok] = i
       #   end
       # }
      end
      @indexedGrammar[i][:firstSet].each{|tok|
        if @parseTable[symbol][tok].nil?
          @parseTable[symbol][tok] = i
        end
      }
    }
    #printParseTable(parseTable)
    #puts "#{@parseTable}"
    @parseTable.each{|key, value|
      @parseTable[key].each{|symbol, inter|
        puts "#{key} x #{symbol} -> #{inter}"
      }
    }
  end

   # fetch firstset for a single symbol
  def getFirstSet(symbol,taboo)
    choices = Grammar::DEFINITIONS[symbol].split('|')
    firstset = []
    choices.each{|choice|
      break if choice == "empty"
      tokens = choice.split(' ')
      tokens.each{|token|
      if !(taboo.include?(token))
        if Grammar::DEFINITIONS.include?(token)
          if Grammar::DEFINITIONS[token].include?("empty")
            firstset += getFirstSet(token, taboo+[token])
          else
            firstset += getFirstSet(token, taboo+[token])
            break
          end
        else
          firstset += [token]
          break
        end
      end
      }
    }
    return firstset
  end

  # fetch followset for a single symbol. this is a pretty bad algo.
  def getFollowSet(firstSet, symbol, taboo)
    #puts "Taboo: #{taboo} | Symbol: #{symbol}"
    return [""] if symbol == "program"
    followset = []
    Grammar::DEFINITIONS.each{|key, value|
      if value.include? symbol
        choices = value.split('|')
        choices.each{|choice|
          tokens = choice.split
          if !tokens.index(symbol).nil?
            nextIndex = tokens.index(symbol) + 1
            #puts "Tokens #{tokens}, Symbol #{symbol}, taboo #{taboo}"
            if tokens.index(symbol) == tokens.size - 1
              if value.include?(key)
                followset += Grammar::DEFINITIONS.include?(key) ? firstSet[key] : [tokens[nextIndex]]
              else
                followset += getFollowSet(firstSet, key, taboo )
              end
            elsif Grammar::DEFINITIONS.include?(tokens[nextIndex]) and Grammar::DEFINITIONS[tokens[nextIndex]].include?("empty")
              followset += getFollowSet(firstSet, tokens[nextIndex], taboo )
              followset += firstSet[tokens[nextIndex]]
            else
              followset += Grammar::DEFINITIONS.include?(tokens[nextIndex]) ? firstSet[tokens[nextIndex]] : [tokens[nextIndex]]
            end
          end
        }
      end
    }
    return followset
  end

  # parseStack, the current stack string we are looking at
  # token, (token[0] info:token[1] value)
  def processSingleToken(token)
    puts "curr stack" 
    @parseStack.each{|i| print "#{i} | "}
    print "\n"
    popped = ""
    begin
      popped = @parseStack.shift
    end while popped == "empty"
    if Grammar::TERMINAL_LIST.include?(popped)
      # If the grammar isn't literal, then it must match a keyword or operation verbosely; token[1]
      # if the grammar is literal, then it only need to match the token type; token[0]
      puts "#{popped} TERMINAL"
      return ( popped == token )
    else
      # for each of the choices (in an OR situation), split, and decide
      # popped = a symbol/nonterminal
      # token[1] = attempt to match

      # puts "#{popped}x#{token}"
      prediction = @parseTable[popped][token]
      if prediction == nil
        @parseTable.each{|key, value|
          @parseTable[key].each{|symbol, inter|
            puts "|#{key}| x |#{symbol}| -> |#{inter}|"
          }
        }
        puts "what failed: |#{popped}| x |#{token}|"
        exit
      end
      interp = @indexedGrammar[prediction][:interp]
      @parseStack = interp.split + @parseStack

      result = processSingleToken(token)

    end
    return result
  end
end

main()
