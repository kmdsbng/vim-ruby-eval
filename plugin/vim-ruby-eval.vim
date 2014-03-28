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
require 'fileutils'

class EvalBuffer
  def initialize
    @buffer = VIM::Buffer.current
    eval_buffer
  end

  def eval_buffer
    lines = []
    (1..@buffer.length).each {|i|
      line = @buffer[i]
      next if line =~ /^(\s*)#/ # if line starts with comment, skip eval
      if line =~ /^(.*)(# =>.*)$/
        line = %Q[__vim_ruby_eval_val = (#{$1});] + %Q[print("# => #{i}:");puts(__vim_ruby_eval_val.inspect.each_line.first)]
      end
      lines << line
    }

    path = write_to_temp_file(lines)
    output, error = run_ruby(path)

    write_result_to_buffer(output, error)
    FileUtils.rm(path)
  end

  def write_result_to_buffer(output, error)
    real_output = []
    clear_eval_result

    # pick inspect values and write to marker comment.
    output.each_line {|line|
      if line =~ /^# => (\d+):(.*)$/
        index = $1.to_i
        val = $2
        @buffer[index] = @buffer[index].gsub(/# =>.*$/, "# => #{val}")
      else
        real_output << line
      end
    }

    real_output.each {|l|
      @buffer.append(@buffer.length, '# >> ' + l.chomp)
    }

    error.each_line {|l|
      @buffer.append(@buffer.length, '# ~> ' + l.chomp)
    }
  end

  def write_to_temp_file(lines)
    path = prepare_temp_path
    open(path, 'w') {|fp|
      lines.each {|l|
        fp.puts l
      }
    }
    path
  end

  # retval: [output, error]
  def run_ruby(path)
    output = error = nil
    Open3.popen3(%Q(ruby #{path})) {|stdin, stdout, stderr|
      stdin.close
      output = stdout.read
      error = stderr.read
    }
    [output, error]
  end

  def prepare_temp_path
    if @buffer.name && !@buffer.name.empty?
      return @buffer.name + ".rubyeval"
    else
      t = Tempfile.open("ruby_eval")
      t.close
      t.path
    end
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


