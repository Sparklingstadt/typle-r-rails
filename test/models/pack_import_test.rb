require "test_helper"

class PackImportTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  def upload(body, filename)
    Rack::Test::UploadedFile.new(StringIO.new(body.b), "text/csv", original_filename: filename)
  end

  def import(body, filename = "取り込み.csv") = PackImport.call(@user, upload(body, filename), default_name: "読み込んだリスト")

  def words(pack) = pack.word_lists.first.words.map { |word| [word.display, word.input, word.annotation, word.input_type] }

  test "a CSV without a header is display, input, annotation per line, named after the file" do
    pack = import("ls,ls,一覧\npwd\n\n", "シェル.csv")

    assert_equal "シェル", pack.name
    assert_equal ["シェル"], pack.word_lists.map(&:name)
    assert_equal [["ls", "ls", "一覧", nil], ["pwd", "pwd", "", nil]], words(pack)
  end

  test "a CSV with typle-r's header is read by its columns, in any order" do
    pack = import("﻿input,anotation,display,input_type\r\nkonnichiwa,挨拶,こんにちは,word\r\n,,,\r\n")

    assert_equal [["こんにちは", "konnichiwa", "挨拶", "word"]], words(pack), "the BOM, the misspelt annotation and the empty row"
  end

  test "a file without a name takes the default one" do
    assert_equal "読み込んだリスト", import("a\n", "").name
  end

  test "typle-r's pack file is imported as a pack file" do
    text = PackFile.encode(OfficialCatalog.follow(@user, "pack-vim-beginner"))
    pack = import(text, "vim.typle-pack.json")

    assert_operator pack.word_lists.size, :>, 1
    # A file that starts with { is a pack file, whatever its name.
    assert_raises(PackFile::Unreadable) { import('{"format":"other"}', "x.csv") }
  end

  test "files that are too large or not UTF-8 are refused" do
    assert_raises(PackImport::TooLarge) { import("a\n" * (PackImport::MAX_SIZE / 2 + 1)) }
    assert_raises(PackImport::NotUtf8) { import("a\xFF,b\n") }
    assert_raises(PackFile::Unreadable) { import("{\xFF", "x.json") }
  end

  test "words a list cannot be saved with save nothing" do
    assert_no_difference -> { Pack.count } do
      assert_raises(ActiveRecord::RecordInvalid) { import("\n\n") }
    end
  end
end
