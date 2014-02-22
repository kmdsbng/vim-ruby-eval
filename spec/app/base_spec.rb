# -*- encoding: utf-8 -*-

describe "VimRubyEval" do
  def temp_path(fname)
    File.join(File.dirname(__FILE__), "temp", fname)
  end

  def write_temp_file(fname, data)
    File.open(temp_path(fname), "w") {|f|
      f.write data
    }
  end

  context "1.rb" do
    before do
      src = <<END
1 # =>
END
      write_temp_file("1.rb", src)
    end

    it "inject result" do
      expect = <<END
1 # => 1
END
      `vim "+RubyEval" "+w" "+q" #{temp_path("1.rb")}`
      File.read(temp_path("1.rb")).should eq(expect)
    end
  end
end

