use super::{apply_preserve_patterns, post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;

pub struct PatternTokenizer {
    config: TokenizerConfig,
    pattern: Regex,
    preserve_patterns: Vec<Regex>,
}

impl PatternTokenizer {
    pub fn new(regex: &str, config: TokenizerConfig) -> Result<Self, String> {
        let pattern = Regex::new(regex).map_err(|e| format!("Invalid regex pattern: {}", e))?;

        let preserve_patterns = config
            .preserve_patterns
            .iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        Ok(Self {
            config,
            pattern,
            preserve_patterns,
        })
    }
}

impl Tokenizer for PatternTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let tokens: Vec<String> = self
            .pattern
            .find_iter(text)
            .map(|mat| mat.as_str().to_string())
            .collect();

        let tokens = if !self.preserve_patterns.is_empty() {
            apply_preserve_patterns(tokens, &self.preserve_patterns, text)
        } else {
            tokens
        };

        post_process(tokens, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}