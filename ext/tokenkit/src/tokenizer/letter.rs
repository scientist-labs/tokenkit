use super::{apply_preserve_patterns, post_process, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;

pub struct LetterTokenizer {
    base: BaseTokenizerFields,
}

impl LetterTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
        }
    }
}

impl Tokenizer for LetterTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let mut current_token = String::new();

        for ch in text.chars() {
            if ch.is_alphabetic() {
                current_token.push(ch);
            } else if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
        }

        if !current_token.is_empty() {
            tokens.push(current_token);
        }

        if self.base.has_preserve_patterns() {
            apply_preserve_patterns(tokens, self.base.preserve_patterns(), text, &self.base.config)
        } else {
            post_process(tokens, &self.base.config)
        }
    }

}