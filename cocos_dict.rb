require "set"

#path = '~/Game/cocos2d-x/cocos/scripting/lua-bindings/auto/api/'
path = './cocos3.0' ## the new api path, the top path will lost some api
                    ## so use the new dir api path some api are in the manual cpp define

curDir = ''
hash = {}
if ARGV.length == 0
    #path = ARGV.first
    curDir = Dir.pwd
    path = File.expand_path path
    Dir.chdir path
    other=[]
    Dir.glob("*.lua") do |afile|
        fname = File.basename(afile,'.lua')
        # if fname.include? '_api'
        if fname == 'cc' or fname == 'ccs' or fname == 'ccui' or fname == 'sp'
            open(afile, 'r') do |file|
                file.readlines.each do |readline|
                    readline.match('@module\s\w+') do |m|
                        mname = m.to_s.split(' ')[1]
                        hash[mname] = hash[mname] || []
                    end
                    readline.match('@field\s.+') do |field|
                        a = field.to_s.split(' ')
                        key = ''
                        value = ''
                        a.each_index do |index|
                            if index == 1
                                if a[index].include? ']'
                                    sidx = a[index].index('#') + 1
                                    eidx = a[index].index(']')
                                    key = a[index][sidx...eidx]
                                    if hash.key? key == false
                                        hash[key] = []
                                    end
                                end
                            elsif index == 2
                                if a[index].include? '#'
                                    m = a[index].match('\w+#\w+')
                                    if m.nil?
                                        value = a[3]
                                    else
                                        m.to_a.each do |item|
                                            eidx = a[index].index('#')
                                            value = a[index][0...eidx]
                                        end
                                    end
                                    # a[index].match('\w+#\w+') do |m|
                                    #     puts m
                                    #     if m.nil?
                                    #         value = a[3]
                                    #         puts value
                                    #     else
                                    #         eidx = a[index].index('#')
                                    #         value = a[index][0...eidx]
                                    #     end
                                    # end
                                end
                            end
                            if key.empty? || value.empty?
                                next
                            end
                            hash[key] << "#{key}.#{value}"
                        end
                    end
                end
            end
        else
            if fname.include?("_api") == false
                other << afile
            end
        end
    end

    #export the data to dict file
    Dir.chdir(curDir)
    open('cocoslua.dict','w') do |f|
        hash.each_pair do |key,value|
            f.write("#{key}\n\n")
            value.sort!.each do |v|
                f.write("#{v}\n")
            end
            f.write("\n")
        end
        if other.empty? == false
            other.sort!
            other.each do |file|
                p = File.basename(file,'.lua')
                f.write("#{p}\n")
            end
            f.write("\n")
        end
    end

    #
    # now write the other methods to the lua dict file
    #
    #
    Dir.chdir(path)
    if other.empty? == false
        s = Set.new
        other.each do |item|
            text = []
            open(item,'r') do |file|
                text = file.readlines
            end
            text.reverse!
            len = text.length
            params = []
            (1..len).each do |i|
                if text[i].nil?
                    next
                else
                    text[i].match('@param\s.+') do |param|
                        a = param.to_s.split(' ')
                        if a[1].include? '#'
                            sidx = a[1].index('#') + 1
                            eidx = a[1].length
                            params << a[1][sidx..eidx]
                        else
                            params << a[1]
                        end
                    end
                    text[i].match('@field\s.+') do |field|
                        s << field.to_s.split(' ')[3]
                    end
                    text[i].match('@function\s.+') do |fun|
                        func = fun.to_s.split(' ').last
                        if params.empty? == false
                            s << func
                            func << '('
                            i = 1
                            l = params.length
                            params.reverse_each do |x|
                                if i == l then func << x end
                                if i != l then func << "#{x}, " end
                                i += 1
                            end
                            func << ')'
                            s << func
                            params.clear
                        else
                            s << func
                        end
                    end
                end
            end
        end
        Dir.chdir(curDir)
        open('cocoslua.dict','a') do |file|
            a = s.to_a
            a.sort!.each do |item|
                file.write "#{item}\n"
            end
        end
    end
else
    puts 'please enter the lua script api example: $COCOS_ROOT/cocos/scripting/lua-binding/auto/api path'
end
