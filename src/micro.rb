#!/usr/bin/env ruby
require './src/grammar'

def main()
    infile = File.new(ARGV[0], "r")
    tokenizeAndParse(infile)
end

def tokenizeAndParse(infile)
    infile.each_line {|line|
        cleanline = (line.include?('--')? line[0..line.index('--')-1] : line)
        cleanline.lstrip! 
        tokens = tokenizeLine(cleanline)
        tokens.each{|toks|
            puts "#{toks[0]}: #{toks[1]}"
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

main()
