use super::{apply_preserve_patterns, post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;
use unicode_segmentation::UnicodeSegmentation;

pub struct UnicodeTokenizer {
    config: TokenizerConfig,
    preserve_patterns: Vec<Regex>,
}

impl UnicodeTokenizer {
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

impl Tokenizer for UnicodeTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        if !self.preserve_patterns.is_empty() {
            let tokens = text
                .unicode_words()
                .map(|s| s.to_string())
                .collect();

            let tokens = apply_preserve_patterns(tokens, &self.preserve_patterns, text);
            return post_process(tokens, &self.config);
        }

        let tokens: Vec<String> = text
            .unicode_words()
            .map(|s| s.to_string())
            .collect();

        post_process(tokens, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}