use super::{apply_preserve_patterns, post_process, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;

pub struct WhitespaceTokenizer {
    base: BaseTokenizerFields,
}

impl WhitespaceTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
        }
    }
}

impl Tokenizer for WhitespaceTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let tokens: Vec<String> = text
            .split_whitespace()
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .collect();

        if self.base.has_preserve_patterns() {
            apply_preserve_patterns(tokens, self.base.preserve_patterns(), text, &self.base.config)
        } else {
            post_process(tokens, &self.base.config)
        }
    }

}