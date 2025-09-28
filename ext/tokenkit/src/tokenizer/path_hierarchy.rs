use super::Tokenizer;
use crate::config::TokenizerConfig;

pub struct PathHierarchyTokenizer {
    config: TokenizerConfig,
    delimiter: String,
}

impl PathHierarchyTokenizer {
    pub fn new(config: TokenizerConfig, delimiter: String) -> Self {
        Self { config, delimiter }
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

        let mut result = tokens;

        if self.config.lowercase {
            result = result.into_iter().map(|t| t.to_lowercase()).collect();
        }

        if self.config.remove_punctuation {
            result = result
                .into_iter()
                .map(|t| {
                    let delimiter = &self.delimiter;
                    t.chars()
                        .map(|c| {
                            if c.to_string() == *delimiter {
                                c
                            } else if c.is_ascii_punctuation() {
                                '\0'
                            } else {
                                c
                            }
                        })
                        .filter(|&c| c != '\0')
                        .collect()
                })
                .filter(|s: &String| !s.is_empty())
                .collect();
        }

        result
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}