use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;

pub struct NgramTokenizer {
    config: TokenizerConfig,
    min_gram: usize,
    max_gram: usize,
}

impl NgramTokenizer {
    pub fn new(config: TokenizerConfig, min_gram: usize, max_gram: usize) -> Self {
        Self {
            config,
            min_gram,
            max_gram,
        }
    }

    fn generate_ngrams(&self, text: &str) -> Vec<String> {
        let mut ngrams = Vec::new();
        let chars: Vec<char> = text.chars().collect();
        let text_len = chars.len();

        if text_len == 0 {
            return ngrams;
        }

        let max = self.max_gram.min(text_len);

        for gram_size in self.min_gram..=max {
            for start in 0..=(text_len - gram_size) {
                let ngram: String = chars.iter().skip(start).take(gram_size).collect();
                ngrams.push(ngram);
            }
        }

        ngrams
    }
}

impl Tokenizer for NgramTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut all_ngrams = Vec::new();

        for word in text.split_whitespace() {
            if word.is_empty() {
                continue;
            }

            let processed_word = if self.config.remove_punctuation {
                word.chars()
                    .filter(|c| !c.is_ascii_punctuation())
                    .collect()
            } else {
                word.to_string()
            };

            if processed_word.is_empty() {
                continue;
            }

            let ngrams = self.generate_ngrams(&processed_word);
            all_ngrams.extend(ngrams);
        }

        post_process(all_ngrams, &self.config)
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}