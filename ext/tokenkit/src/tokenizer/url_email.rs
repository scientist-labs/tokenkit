use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use regex::Regex;
use unicode_segmentation::UnicodeSegmentation;

pub struct UrlEmailTokenizer {
    config: TokenizerConfig,
    email_regex: Regex,
    url_regex: Regex,
}

impl UrlEmailTokenizer {
    pub fn new(config: TokenizerConfig) -> Result<Self, String> {
        let email_regex = Regex::new(
            r"(?i)[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}"
        ).map_err(|e| format!("Failed to compile email regex: {}", e))?;

        let url_regex = Regex::new(
            r"(?i)https?://[a-z0-9.-]+(?:\.[a-z]{2,})?(?:/[^\s]*)?"
        ).map_err(|e| format!("Failed to compile URL regex: {}", e))?;

        Ok(Self {
            config,
            email_regex,
            url_regex,
        })
    }

    fn extract_url_email_spans(&self, text: &str) -> Vec<(usize, usize, String)> {
        let mut spans = Vec::new();

        for mat in self.email_regex.find_iter(text) {
            spans.push((mat.start(), mat.end(), mat.as_str().to_string()));
        }

        for mat in self.url_regex.find_iter(text) {
            spans.push((mat.start(), mat.end(), mat.as_str().to_string()));
        }

        spans.sort_by_key(|s| s.0);
        spans
    }
}

impl Tokenizer for UrlEmailTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let spans = self.extract_url_email_spans(text);

        if spans.is_empty() {
            let tokens: Vec<String> = text
                .unicode_words()
                .map(|s| s.to_string())
                .collect();
            return post_process(tokens, &self.config);
        }

        let mut result = Vec::new();
        let mut pos = 0;

        for (start, end, url_or_email) in spans {
            if start > pos {
                let before = &text[pos..start];
                let before_tokens: Vec<String> = before
                    .unicode_words()
                    .map(|s| s.to_string())
                    .collect();
                let before_tokens = post_process(before_tokens, &self.config);
                result.extend(before_tokens);
            }

            let preserved = if self.config.lowercase {
                url_or_email.to_lowercase()
            } else {
                url_or_email
            };
            result.push(preserved);
            pos = end;
        }

        if pos < text.len() {
            let remaining = &text[pos..];
            let remaining_tokens: Vec<String> = remaining
                .unicode_words()
                .map(|s| s.to_string())
                .collect();
            let remaining_tokens = post_process(remaining_tokens, &self.config);
            result.extend(remaining_tokens);
        }

        result
    }

    fn config(&self) -> &TokenizerConfig {
        &self.config
    }
}