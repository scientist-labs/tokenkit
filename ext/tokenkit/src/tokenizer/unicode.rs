use super::{apply_preserve_patterns, post_process, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;
use unicode_segmentation::UnicodeSegmentation;

pub struct UnicodeTokenizer {
    base: BaseTokenizerFields,
}

impl UnicodeTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
        }
    }
}

impl Tokenizer for UnicodeTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        if self.base.has_preserve_patterns() {
            let tokens = text
                .unicode_words()
                .map(|s| s.to_string())
                .collect();

            return apply_preserve_patterns(tokens, self.base.preserve_patterns(), text, &self.base.config);
        }

        let tokens: Vec<String> = text
            .unicode_words()
            .map(|s| s.to_string())
            .collect();

        post_process(tokens, &self.base.config)
    }

}