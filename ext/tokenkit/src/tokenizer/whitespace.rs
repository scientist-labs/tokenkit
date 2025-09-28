use super::{apply_preserve_patterns, post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;

pub struct WhitespaceTokenizer {
    config: TokenizerConfig,
    preserve_patterns: Vec<Regex>,
}

impl WhitespaceTokenizer {
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

impl Tokenizer for WhitespaceTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let tokens: Vec<String> = text
            .split_whitespace()
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .collect();

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