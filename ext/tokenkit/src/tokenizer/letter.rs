use super::{apply_preserve_patterns, post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;

pub struct LetterTokenizer {
    config: TokenizerConfig,
    preserve_patterns: Vec<Regex>,
}

impl LetterTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        let preserve_patterns = config
            .preserve_patterns
            .iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        Self {
            config,
            preserve_patterns,
        }
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