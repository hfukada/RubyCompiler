#!/usr/bin/env ruby
require './src/grammar'

def main()
    infile = File.new(ARGV[0], "r")
    infile.each_line {|line|
       cleanline = (line.include?('--')? line[0..line.index('--')-1] : line)
       cleanline.lstrip! 
       currFront,i = 0,0
       found=false
       while i < cleanline.length
            found = false
            if !(cleanline[i] =~ (Grammar::SINGLEOP)).nil?
                basetok = cleanline[currFront..i-1]

                if !(basetok =~ /^;/).nil?
                    puts "Token Type: OPERATOR\nValue: ;"
                    break
                end
                if (cleanline[i] =~ /"|'/).nil?
                    if !(basetok.strip =~ (Grammar::KEYWORD)).nil?
                        puts "Token Type: KEYWORD\nValue: #{basetok.strip}"
                        found = true
                    elsif (basetok.strip =~ (Grammar::OPERATOR)).nil?
                        if !(basetok.strip =~ (Grammar::INTLITERAL)).nil?
                            puts "Token Type: INTLITERAL\nValue: #{basetok.strip}"
                        elsif !(basetok.strip =~ (Grammar::FLOATLITERAL)).nil?
                            puts "Token Type: FLOATLITERAL\nValue: #{basetok.strip}"
                        else
                            puts "Token Type: IDENTIFIER\nValue: #{basetok.strip}" if basetok.strip.length > 0
                        end
                        found = true
                    end
                    if cleanline[i] != ' '
                        if !(cleanline[i..i+1] =~ (Grammar::OPERATOR)).nil?
                            puts "Token Type: OPERATOR\nValue: #{cleanline[i..i+1]}"
                            i += 1
                        elsif !(cleanline[i] =~ (Grammar::OPERATOR)).nil? 
                            puts "Token Type: OPERATOR\nValue: #{cleanline[i]}"
                        end
                        found = true
                    end
                else 
                    endQuo = cleanline.index(/'|"/,i+1)
                    puts "Token Type: STRINGLITERAL\nValue: #{cleanline[i..endQuo]}"
                    i = endQuo
                    found = true
                end
            end
            i += 1 
            if found
                currFront = i
            end
        end

    }
    infile.close
end

main()
