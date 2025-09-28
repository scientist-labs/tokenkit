use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use unicode_segmentation::UnicodeSegmentation;

pub struct SentenceTokenizer {
    config: TokenizerConfig,
}

impl SentenceTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }
}

impl Tokenizer for SentenceTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let sentences: Vec<String> = text
            .unicode_sentences()
            .map(|s| s.to_string())
            .collect();

        post_process(sentences, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}