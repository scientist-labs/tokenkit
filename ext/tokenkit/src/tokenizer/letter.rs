use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;

pub struct LetterTokenizer {
    config: TokenizerConfig,
}

impl LetterTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }
}

impl Tokenizer for LetterTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut current_token = String::new();

        for ch in text.chars() {
            if ch.is_alphabetic() {
                current_token.push(ch);
            } else if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
        }

        if !current_token.is_empty() {
            tokens.push(current_token);
        }

        post_process(tokens, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}