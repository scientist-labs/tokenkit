use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use unicode_segmentation::UnicodeSegmentation;

pub struct GraphemeTokenizer {
    config: TokenizerConfig,
    extended: bool,
}

impl GraphemeTokenizer {
    pub fn new(config: TokenizerConfig, extended: bool) -> Self {
        Self { config, extended }
    }
}

impl Tokenizer for GraphemeTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let graphemes: Vec<String> = text
            .graphemes(self.extended)
            .map(|s| s.to_string())
            .collect();

        post_process(graphemes, &self.config)
    }

}