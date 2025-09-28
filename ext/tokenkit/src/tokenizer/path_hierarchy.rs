use super::{apply_preserve_patterns, post_process_with_preserved, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;

pub struct PathHierarchyTokenizer {
    config: TokenizerConfig,
    delimiter: String,
    preserve_patterns: Vec<Regex>,
}

impl PathHierarchyTokenizer {
    pub fn new(config: TokenizerConfig, delimiter: String) -> Self {
        let preserve_patterns = config
            .preserve_patterns
            .iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        Self {
            config,
            delimiter,
            preserve_patterns,
        }
    }

    fn generate_hierarchy(&self, path: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let parts: Vec<&str> = path.split(&self.delimiter).collect();

        let mut current_path = String::new();
        let starts_with_delimiter = path.starts_with(&self.delimiter);

        for part in parts.iter() {
            if part.is_empty() {
                continue;
            }

            if !current_path.is_empty() {
                current_path.push_str(&self.delimiter);
            } else if starts_with_delimiter {
                current_path.push_str(&self.delimiter);
            }

            current_path.push_str(part);
            tokens.push(current_path.clone());
        }

        tokens
    }
}

impl Tokenizer for PathHierarchyTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return vec![];
        }

        let tokens = self.generate_hierarchy(trimmed);

        if !self.preserve_patterns.is_empty() {
            // Apply preserve_patterns to maintain original case for matched patterns
            apply_preserve_patterns(tokens, &self.preserve_patterns, trimmed, &self.config)
        } else {
            post_process_with_preserved(tokens, &self.config, Some(&self.delimiter))
        }
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}