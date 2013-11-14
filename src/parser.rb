class RubyCompiler
  def createParseTable()
    firstSet={}
    Grammar::DEFINITIONS.each{|symbol, interp|
      @parseTable[symbol] ={}
      firstSet[symbol] = getFirstSet(symbol,[symbol]).uniq
    }
    followSet={}
    Grammar::DEFINITIONS.each{|symbol, interp|
      followSet[symbol] = getFollowSet(firstSet,symbol).uniq
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
            @parseTable[symbol][tok] = i
          }
        else
          @parseTable[symbol][tokens[0]] = i
        end
      end
      @indexedGrammar[i][:firstSet].each{|tok|
        if @parseTable[symbol][tok].nil?
          @parseTable[symbol][tok] = i
        end
      }
    }
  end

  # fetch firstset for a single symbol
  def getFirstSet(symbol,taboo)
    choices = Grammar::DEFINITIONS[symbol].split('|')
    firstset = []
    choices.each{|choice|
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
          firstset += (token == "empty" ? [] :[token])
          break
        end
      end
      }
    }
    return firstset
  end

  # fetch followset for a single symbol. this is a pretty bad algo.
  def getFollowSet(firstSet, symbol)
    return [""] if symbol == "program"
    followset = []
    Grammar::DEFINITIONS.each{|key, value|
      if value.include? symbol
        choices = value.split('|')
        choices.each{|choice|
          tokens = choice.split
          if !tokens.index(symbol).nil?
            nextIndex = tokens.index(symbol) + 1
            if tokens.index(symbol) == tokens.size - 1
              if tokens[tokens.size-1] == key
                followset += Grammar::DEFINITIONS.include?(key) ? firstSet[key] : [tokens[nextIndex]]
              else
                followset += getFollowSet(firstSet, key)
              end
            elsif Grammar::DEFINITIONS.include?(tokens[nextIndex]) 
              if Grammar::DEFINITIONS[tokens[nextIndex]].include?("empty")
                followset += getFollowSet(firstSet, tokens[nextIndex])
              end
              followset += firstSet[tokens[nextIndex]]
            else
              followset += [tokens[nextIndex]]
            end
          end
        }
      end
    }
    return followset
  end

  # parseStack, the current stack string we are looking at
  # token, (token[0] info:token[1] value)
  def processSingleToken(token,value)
    popped = ""
    popped = @parseStack.shift
    while (popped[0] == "empty")
      popped = @parseStack.shift
    end
    if Grammar::TERMINAL_LIST.include?(popped[0])
      # If the grammar isn't literal, then it must match a keyword or operation verbosely; token[1]
      # if the grammar is literal, then it only need to match the token type; token[0]
      if !@baseExprStack.nil?
        @baseExprStack.push [value, popped[1]]
      elsif !@baseIfStack.nil?
        @baseIfStack.push [value, popped[1]]
      elsif value == 'WHILE' or value == 'DO' or !@baseWhileStack.nil?
        if @baseWhileStack.nil?
          @baseWhileStack=[[value, popped[1]]]
        else
          if @baseWhileStack[0][0] == 'WHILE'
            @baseWhileStack.push [value,popped[1]]
          end
        end
      end
      return ( popped[0] == token ) ? popped : "error"
    else
      # for each of the choices (in an OR situation), split, and decide
      # popped = a symbol/nonterminal
      # token[1] = attempt to match

      if popped[0] == "base_stmt"
        @baseExprStack = []
      elsif popped[0] == "if_stmt" or popped[0] == "else_part"
        @baseIfStack = []
      end

      prediction = @parseTable[popped[0]][token]
      if prediction == nil
        @parseTable.each{|key, value|
          @parseTable[key].each{|symbol, inter|
            puts "|#{key}| x |#{symbol}| -> |#{inter}|"
          }
        }
        puts @parseStack
        puts "Could not parse: |#{popped[0]}| x |#{token}|"
        return 1, "Could not parse: |#{popped[0]}| x |#{token}|"
      end
      interp = @indexedGrammar[prediction][:interp]
      @parseStack = interp.split.zip([popped[0]]*interp.split.size) + @parseStack

      return processSingleToken(token,value)

    end
  end
end
