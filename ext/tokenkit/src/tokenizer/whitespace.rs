use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;

pub struct WhitespaceTokenizer {
    config: TokenizerConfig,
}

impl WhitespaceTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }
}

impl Tokenizer for WhitespaceTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let tokens: Vec<String> = text
            .split_whitespace()
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .collect();

        post_process(tokens, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}