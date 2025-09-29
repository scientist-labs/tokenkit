use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;
use unicode_segmentation::UnicodeSegmentation;

pub struct SentenceTokenizer {
    config: TokenizerConfig,
    preserve_patterns: Vec<Regex>,
}

impl SentenceTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        let preserve_patterns = config
            .preserve_patterns
            .iter()
            .filter_map(|p| Regex::new(p).ok())
            .collect();

        Self {
            config,
            preserve_patterns,
        }
    }
}

impl SentenceTokenizer {
    fn apply_patterns_to_sentence(&self, sentence: &str) -> String {
        if self.preserve_patterns.is_empty() || !self.config.lowercase {
            return sentence.to_string();
        }

        // Find all matches in the sentence
        let mut preserved_spans: Vec<(usize, usize, String)> = Vec::new();
        for pattern in &self.preserve_patterns {
            for mat in pattern.find_iter(sentence) {
                preserved_spans.push((mat.start(), mat.end(), mat.as_str().to_string()));
            }
        }

        if preserved_spans.is_empty() {
            return sentence.to_string();
        }

        // Sort and merge overlapping spans
        preserved_spans.sort_by(|a, b| a.0.cmp(&b.0).then_with(|| b.1.cmp(&a.1)));

        let mut result = String::new();
        let mut pos = 0;

        for (start, end, preserved) in preserved_spans {
            if start > pos {
                // Lowercase the text before the preserved pattern
                result.push_str(&sentence[pos..start].to_lowercase());
            }
            // Keep the preserved pattern as-is
            result.push_str(&preserved);
            pos = end.max(pos); // Handle overlaps
        }

        if pos < sentence.len() {
            // Lowercase the remaining text
            result.push_str(&sentence[pos..].to_lowercase());
        }

        result
    }
}

impl Tokenizer for SentenceTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let mut sentences: Vec<String> = text
            .unicode_sentences()
            .map(|s| s.to_string())
            .collect();

        // Apply preserve patterns to each sentence
        if !self.preserve_patterns.is_empty() && self.config.lowercase {
            sentences = sentences
                .into_iter()
                .map(|sentence| self.apply_patterns_to_sentence(&sentence))
                .collect();

            // Don't call post_process since we already handled lowercasing with patterns
            // Just handle remove_punctuation if needed
            if self.config.remove_punctuation {
                sentences = sentences
                    .into_iter()
                    .map(|s| s.chars().filter(|c| !c.is_ascii_punctuation()).collect())
                    .filter(|s: &String| !s.is_empty())
                    .collect();
            }
            sentences
        } else {
            post_process(sentences, &self.config)
        }
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}