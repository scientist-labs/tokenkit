use crate::config::TokenizerConfig;
use regex::Regex;

/// Common functionality for tokenizers that support preserve_patterns
pub fn create_preserve_patterns(config: &TokenizerConfig) -> Vec<Regex> {
    config
        .preserve_patterns
        .iter()
        .filter_map(|p| {
            match Regex::new(p) {
                Ok(regex) => Some(regex),
                Err(e) => {
                    // TODO: Phase 6 - Add proper error handling/logging here
                    eprintln!("Warning: Invalid regex pattern '{}': {}", p, e);
                    None
                }
            }
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

    pub fn config(&self) -> &TokenizerConfig {
        &self.config
    }

    pub fn has_preserve_patterns(&self) -> bool {
        !self.preserve_patterns.is_empty()
    }

    pub fn preserve_patterns(&self) -> &[Regex] {
        &self.preserve_patterns
    }
}

