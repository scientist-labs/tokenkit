use super::{apply_preserve_patterns, post_process, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;
use crate::error::Result;
use regex::Regex;

pub struct PatternTokenizer {
    base: BaseTokenizerFields,
    pattern: Regex,
}

impl PatternTokenizer {
    pub fn new(regex: &str, config: TokenizerConfig) -> Result<Self> {
        // Pattern is already validated in validate_config(), safe to unwrap
        let pattern = Regex::new(regex).expect("Pattern should have been validated");

        Ok(Self {
            base: BaseTokenizerFields::new(config),
            pattern,
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

        if self.base.has_preserve_patterns() {
            apply_preserve_patterns(tokens, self.base.preserve_patterns(), text, &self.base.config)
        } else {
            post_process(tokens, &self.base.config)
        }
    }

}