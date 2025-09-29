use crate::config::TokenizerConfig;
use regex::Regex;

/// Common functionality for tokenizers that support preserve_patterns
/// Note: Since we validate patterns in validate_config(), they're guaranteed to be valid here
pub fn create_preserve_patterns(config: &TokenizerConfig) -> Vec<Regex> {
    config
        .preserve_patterns
        .iter()
        .map(|p| {
            // Safe to unwrap because patterns are validated in validate_config()
            Regex::new(p).expect("Pattern should have been validated")
        })
        .collect()
}

/// Base fields that most tokenizers need
pub struct BaseTokenizerFields {
    pub config: TokenizerConfig,
    pub preserve_patterns: Vec<Regex>,
}

impl BaseTokenizerFields {
    pub fn new(config: TokenizerConfig) -> Self {
        let preserve_patterns = create_preserve_patterns(&config);
        Self {
            config,
            preserve_patterns,
        }
    }


    pub fn has_preserve_patterns(&self) -> bool {
        !self.preserve_patterns.is_empty()
    }

    pub fn preserve_patterns(&self) -> &[Regex] {
        &self.preserve_patterns
    }
}

