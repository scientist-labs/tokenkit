use super::Tokenizer;
use crate::config::TokenizerConfig;

pub struct LowercaseTokenizer {
    config: TokenizerConfig,
}

impl LowercaseTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }
}

impl Tokenizer for LowercaseTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut current_token = String::new();

        for ch in text.chars() {
            if ch.is_alphabetic() {
                current_token.push(ch.to_lowercase().next().unwrap_or(ch));
            } else if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
        }

        if !current_token.is_empty() {
            tokens.push(current_token);
        }

        // Lowercase tokenizer always lowercases, ignore config.lowercase
        // Only apply remove_punctuation if configured
        if self.config.remove_punctuation {
            tokens = tokens
                .into_iter()
                .map(|t| {
                    t.chars()
                        .filter(|c| !c.is_ascii_punctuation())
                        .collect()
                })
                .filter(|s: &String| !s.is_empty())
                .collect();
        }

        tokens
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}