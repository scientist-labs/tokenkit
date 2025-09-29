RSpec.describe "Pattern Preservation" do
  after { TokenKit.reset }

  context "with single-token patterns" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+(ug|mg|ml)/i]
      end
    end

    it "preserves measurement units" do
      tokens = TokenKit.tokenize("Give patient 100ug daily dose")
      expect(tokens).to include("100ug", "give", "patient", "daily", "dose")
    end

    it "preserves case in pattern matches" do
      tokens = TokenKit.tokenize("100UG dose", lowercase: false)
      expect(tokens).to include("100UG")
    end
  end

  context "with multi-word patterns" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/anti-cd\d+/i, /\w+(?:-\w+)+/i]
      end
    end

    it "preserves hyphenated terms matching pattern" do
      tokens = TokenKit.tokenize("anti-cd3 antibody treatment")
      expect(tokens).to include("anti-cd3", "antibody", "treatment")
    end

    it "preserves multi-hyphen terms" do
      tokens = TokenKit.tokenize("top-of-the-line product")
      expect(tokens).to include("top-of-the-line", "product")
    end
  end

  context "with overlapping patterns" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+/, /\d+mg/i]
      end
    end

    it "uses first matching pattern" do
      tokens = TokenKit.tokenize("Take 100mg daily")
      expect(tokens).to include("100mg", "take", "daily")
    end
  end

  context "without preserve patterns" do
    it "splits hyphenated terms normally" do
      tokens = TokenKit.tokenize("anti-cd3 antibody")
      expect(tokens).to eq(["anti", "cd3", "antibody"])
    end
  end

  context "error handling" do
    it "raises error for invalid regex patterns" do
      expect {
        TokenKit.configure do |config|
          config.preserve_patterns = ["[invalid(regex"]
        end
      }.to raise_error(RegexpError, /Invalid regex pattern/)
    end
  end
end
