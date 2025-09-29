use super::{Tokenizer};
use crate::config::TokenizerConfig;

pub struct EdgeNgramTokenizer {
    config: TokenizerConfig,
    min_gram: usize,
    max_gram: usize,
}

impl EdgeNgramTokenizer {
    pub fn new(config: TokenizerConfig, min_gram: usize, max_gram: usize) -> Self {
        // Validate and sanitize parameters
        let min_gram = min_gram.max(1); // Minimum 1 character
        let max_gram = max_gram.max(min_gram); // Ensure max >= min

        Self { config, min_gram, max_gram }
    }

    fn generate_edge_ngrams(&self, text: &str) -> Vec<String> {
        let mut ngrams = Vec::new();
        let chars: Vec<char> = text.chars().collect();
        let text_len = chars.len();

        if text_len == 0 {
            return ngrams;
        }

        let max = self.max_gram.min(text_len);

        for gram_size in self.min_gram..=max {
            let ngram: String = chars.iter().take(gram_size).collect();
            ngrams.push(ngram);
        }

        ngrams
    }
}

impl Tokenizer for EdgeNgramTokenizer {
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

            let ngrams = self.generate_edge_ngrams(&processed_word);
            all_ngrams.extend(ngrams);
        }

        let mut result = all_ngrams;

        if self.config.lowercase {
            result = result.into_iter().map(|t| t.to_lowercase()).collect();
        }

        result
    }

}