use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;

pub struct KeywordTokenizer {
    config: TokenizerConfig,
}

impl KeywordTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }
}

impl Tokenizer for KeywordTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return vec![];
        }

        let tokens = vec![trimmed.to_string()];
        post_process(tokens, &self.config)
    }

}