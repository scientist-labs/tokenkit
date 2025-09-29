use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use std::collections::HashSet;

pub struct CharGroupTokenizer {
    config: TokenizerConfig,
    split_chars: HashSet<char>,
}

impl CharGroupTokenizer {
    pub fn new(config: TokenizerConfig, split_on_chars: String) -> Self {
        // Note: Empty split_on_chars is valid - it makes the tokenizer behave like
        // a keyword tokenizer (no splitting, returns whole text as single token)
        let split_chars: HashSet<char> = split_on_chars.chars().collect();
        Self {
            config,
            split_chars,
        }
    }
}

impl Tokenizer for CharGroupTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut current_token = String::new();

        for ch in text.chars() {
            if self.split_chars.contains(&ch) {
                if !current_token.is_empty() {
                    tokens.push(current_token.clone());
                    current_token.clear();
                }
            } else {
                current_token.push(ch);
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