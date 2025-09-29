use super::{apply_preserve_patterns, post_process_with_preserved, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;

pub struct PathHierarchyTokenizer {
    base: BaseTokenizerFields,
    delimiter: String,
}

impl PathHierarchyTokenizer {
    pub fn new(config: TokenizerConfig, delimiter: String) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
            delimiter,
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

        if self.base.has_preserve_patterns() {
            // Apply preserve_patterns to maintain original case for matched patterns
            apply_preserve_patterns(tokens, self.base.preserve_patterns(), trimmed, &self.base.config)
        } else {
            post_process_with_preserved(tokens, &self.base.config, Some(&self.delimiter))
        }
    }

}