" Author:  kmdsbng <kameda.sbng@gmail.com>
" License: The MIT License
" URL:     http://github.com/kmdsbng/vim-ruby-eval/

if exists("loaded_vim_ruby_eval")
    finish
endif
let loaded_vim_ruby_eval = 1


function! RubyEval()
ruby << EOF
require 'tempfile'
require 'open3'

class EvalBuffer
  def initialize
    @buffer = VIM::Buffer.current
    eval_buffer
  end

  def eval_buffer
    lines = []
    (1..@buffer.length).each {|i|
      line = @buffer[i]
      if line =~ /^(.*)(# =>.*)$/
        line = %Q[__vim_ruby_eval_val = (#{$1});] + %Q[print("# => #{i}:");puts(__vim_ruby_eval_val.inspect.each_line.first)]
      end
      lines << line
    }
    t = Tempfile.open("ruby_eval")
    path = t.path
    t.close
    File.open(path, 'w') {|fp|
      lines.each {|l|
        fp.puts l
      }
      fp.path
    }
    result = errors = nil
    Open3.popen3(%Q(ruby #{path})) {|stdin, stdout, stderr|
      stdin.close
      result = stdout.read
      errors = stderr.read
    }
    appends = []

    clear_eval_result

    result.each_line {|line|
      if line =~ /^# => (\d+):(.*)$/
        index = $1.to_i
        val = $2
        @buffer[index] = @buffer[index].gsub(/# =>.*$/, "# => #{val}")
      else
        appends << line
      end
    }

    appends.each {|l|
      @buffer.append(@buffer.length, '# >> ' + l.chomp)
    }

    errors.each_line {|l|
      @buffer.append(@buffer.length, '# ~> ' + l.chomp)
    }
  end

  def clear_eval_result
    (1..@buffer.length).each {|i|
      line = @buffer[i]
      if line =~ /^(.*)(# =>.*)$/
        @buffer[i] = $1 + '# =>'
      end
    }

    while(@buffer.length > 0)
      if @buffer[@buffer.length] =~ /^(\# \>\>|\# \~\>)/
        @buffer.delete(@buffer.length)
      else
        break
      end
    end
  end
end
gem = EvalBuffer.new
EOF
endfunction

command! -nargs=0 RubyEval call RubyEval()


