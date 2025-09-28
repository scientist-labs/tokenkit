mod whitespace;
mod unicode;
mod pattern;

pub use whitespace::WhitespaceTokenizer;
pub use unicode::UnicodeTokenizer;
pub use pattern::PatternTokenizer;

use crate::config::{TokenizerConfig, TokenizerStrategy};
use regex::Regex;

pub trait Tokenizer: Send + Sync {
    fn tokenize(&self, text: &str) -> Vec<String>;
    fn config(&self) -> &TokenizerConfig;
}

pub fn from_config(config: TokenizerConfig) -> Result<Box<dyn Tokenizer>, String> {
    match &config.strategy {
        TokenizerStrategy::Whitespace => Ok(Box::new(WhitespaceTokenizer::new(config))),
        TokenizerStrategy::Unicode => Ok(Box::new(UnicodeTokenizer::new(config))),
        TokenizerStrategy::Pattern { regex } => {
            let regex_clone = regex.clone();
            PatternTokenizer::new(&regex_clone, config)
                .map(|t| Box::new(t) as Box<dyn Tokenizer>)
        }
    }
}

pub(crate) fn apply_preserve_patterns(
    tokens: Vec<String>,
    preserve_patterns: &[Regex],
    original_text: &str,
) -> Vec<String> {
    if preserve_patterns.is_empty() {
        return tokens;
    }

    let mut preserved_spans: Vec<(usize, usize, String)> = Vec::new();
    for pattern in preserve_patterns {
        for mat in pattern.find_iter(original_text) {
            preserved_spans.push((mat.start(), mat.end(), mat.as_str().to_string()));
        }
    }

    if preserved_spans.is_empty() {
        return tokens;
    }

    preserved_spans.sort_by_key(|(start, _, _)| *start);

    let mut result = Vec::new();
    let mut pos = 0;

    for (start, end, preserved) in preserved_spans {
        let before = &original_text[pos..start];
        let before_tokens = tokenize_simple(before);
        result.extend(before_tokens);
        result.push(preserved);
        pos = end;
    }

    if pos < original_text.len() {
        let remaining = &original_text[pos..];
        let remaining_tokens = tokenize_simple(remaining);
        result.extend(remaining_tokens);
    }

    result
}

fn tokenize_simple(text: &str) -> Vec<String> {
    text.split_whitespace()
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
        .collect()
}

pub(crate) fn post_process(mut tokens: Vec<String>, config: &TokenizerConfig) -> Vec<String> {
    if config.lowercase {
        tokens = tokens.into_iter().map(|t| t.to_lowercase()).collect();
    }

    if config.remove_punctuation {
        tokens = tokens
            .into_iter()
            .map(|t| {
                t.chars()
                    .filter(|c| !c.is_ascii_punctuation())
                    .collect()
            })
            .filter(|s: &String| !s.is_empty())
            .collect();
    }

    tokens
}