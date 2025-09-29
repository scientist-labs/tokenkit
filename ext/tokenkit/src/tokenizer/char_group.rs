use super::{apply_preserve_patterns, post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;
use std::collections::HashSet;

pub struct CharGroupTokenizer {
    config: TokenizerConfig,
    split_chars: HashSet<char>,
    preserve_patterns: Vec<Regex>,
}

impl CharGroupTokenizer {
    pub fn new(config: TokenizerConfig, split_on_chars: String) -> Self {
        // Note: Empty split_on_chars is valid - it makes the tokenizer behave like
        // a keyword tokenizer (no splitting, returns whole text as single token)
        let split_chars: HashSet<char> = split_on_chars.chars().collect();
        let preserve_patterns = config
            .preserve_patterns
            .iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        Self {
            config,
            split_chars,
            preserve_patterns,
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

        if !self.preserve_patterns.is_empty() {
            apply_preserve_patterns(tokens, &self.preserve_patterns, text, &self.config)
        } else {
            post_process(tokens, &self.config)
        }
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}