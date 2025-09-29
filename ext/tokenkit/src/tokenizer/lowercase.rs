use super::{apply_preserve_patterns, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;

pub struct LowercaseTokenizer {
    base: BaseTokenizerFields,
}

impl LowercaseTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
        }
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

        if self.base.has_preserve_patterns() {
            // For preserve_patterns, we need to pass a modified config that doesn't lowercase
            // because apply_preserve_patterns handles lowercasing for non-preserved tokens
            let mut modified_config = self.base.config().clone();
            modified_config.lowercase = true; // Force lowercase for non-preserved tokens
            apply_preserve_patterns(tokens, self.base.preserve_patterns(), text, &modified_config)
        } else {
            tokens
        }
    }

    fn config(&self) -> &TokenizerConfig {
        self.base.config()
    }
}