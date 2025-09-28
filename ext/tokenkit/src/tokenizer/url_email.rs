use super::{post_process, Tokenizer};
use crate::config::TokenizerConfig;
use linkify::{LinkFinder, LinkKind};
use unicode_segmentation::UnicodeSegmentation;

pub struct UrlEmailTokenizer {
    config: TokenizerConfig,
}

impl UrlEmailTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self { config }
    }

    fn extract_url_email_spans(&self, text: &str) -> Vec<(usize, usize, String)> {
        let finder = LinkFinder::new();
        let mut spans = Vec::new();

        for link in finder.links(text) {
            match link.kind() {
                LinkKind::Url | LinkKind::Email => {
                    let (start, end) = (link.start(), link.end());
                    spans.push((start, end, link.as_str().to_string()));
                }
                _ => {}
            }
        }

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