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
                for lowercase_ch in ch.to_lowercase() {
                    current_token.push(lowercase_ch);
                }
            } else if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
        }

        if !current_token.is_empty() {
            tokens.push(current_token);
        }

        // Lowercase tokenizer always lowercases, ignore config.lowercase
        // Note: remove_punctuation has no effect since we already split on non-alphabetic
        // characters, but we keep it for consistency with the Tokenizer interface
        tokens
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}