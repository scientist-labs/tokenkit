mod whitespace;
mod unicode;
mod pattern;
mod sentence;
mod grapheme;
mod keyword;
mod edge_ngram;
mod ngram;
mod path_hierarchy;
mod url_email;
mod char_group;
mod letter;
mod lowercase;

pub use whitespace::WhitespaceTokenizer;
pub use unicode::UnicodeTokenizer;
pub use pattern::PatternTokenizer;
pub use sentence::SentenceTokenizer;
pub use grapheme::GraphemeTokenizer;
pub use keyword::KeywordTokenizer;
pub use edge_ngram::EdgeNgramTokenizer;
pub use ngram::NgramTokenizer;
pub use path_hierarchy::PathHierarchyTokenizer;
pub use url_email::UrlEmailTokenizer;
pub use char_group::CharGroupTokenizer;
pub use letter::LetterTokenizer;
pub use lowercase::LowercaseTokenizer;

use crate::config::{TokenizerConfig, TokenizerStrategy};
use regex::Regex;

pub trait Tokenizer: Send + Sync {
    fn tokenize(&self, text: &str) -> Vec<String>;
    fn config(&self) -> &TokenizerConfig;
}

pub fn from_config(config: TokenizerConfig) -> Result<Box<dyn Tokenizer>, String> {
    match config.strategy.clone() {
        TokenizerStrategy::Whitespace => Ok(Box::new(WhitespaceTokenizer::new(config))),
        TokenizerStrategy::Unicode => Ok(Box::new(UnicodeTokenizer::new(config))),
        TokenizerStrategy::Pattern { regex } => {
            PatternTokenizer::new(&regex, config)
                .map(|t| Box::new(t) as Box<dyn Tokenizer>)
        }
        TokenizerStrategy::Sentence => Ok(Box::new(SentenceTokenizer::new(config))),
        TokenizerStrategy::Grapheme { extended } => {
            Ok(Box::new(GraphemeTokenizer::new(config, extended)))
        }
        TokenizerStrategy::Keyword => Ok(Box::new(KeywordTokenizer::new(config))),
        TokenizerStrategy::EdgeNgram { min_gram, max_gram } => {
            Ok(Box::new(EdgeNgramTokenizer::new(config, min_gram, max_gram)))
        }
        TokenizerStrategy::PathHierarchy { delimiter } => {
            Ok(Box::new(PathHierarchyTokenizer::new(config, delimiter)))
        }
        TokenizerStrategy::UrlEmail => {
            Ok(Box::new(UrlEmailTokenizer::new(config)))
        }
        TokenizerStrategy::Ngram { min_gram, max_gram } => {
            Ok(Box::new(NgramTokenizer::new(config, min_gram, max_gram)))
        }
        TokenizerStrategy::CharGroup { split_on_chars } => {
            Ok(Box::new(CharGroupTokenizer::new(config, split_on_chars)))
        }
        TokenizerStrategy::Letter => Ok(Box::new(LetterTokenizer::new(config))),
        TokenizerStrategy::Lowercase => Ok(Box::new(LowercaseTokenizer::new(config))),
    }
}

pub(crate) fn merge_overlapping_spans(mut spans: Vec<(usize, usize, String)>) -> Vec<(usize, usize, String)> {
    if spans.is_empty() {
        return spans;
    }

    spans.sort_by(|a, b| {
        a.0.cmp(&b.0)
            .then_with(|| b.1.cmp(&a.1))
    });

    let mut merged = Vec::new();
    let mut current = spans[0].clone();

    for span in spans.into_iter().skip(1) {
        if span.0 < current.1 {
            if span.1 > current.1 {
                current = span;
            }
        } else {
            merged.push(current);
            current = span;
        }
    }
    merged.push(current);

    merged
}

pub(crate) fn apply_preserve_patterns(
    tokens: Vec<String>,
    preserve_patterns: &[Regex],
    original_text: &str,
    config: &TokenizerConfig,
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

    let preserved_spans = merge_overlapping_spans(preserved_spans);

    let mut result = Vec::new();
    let mut pos = 0;

    for (start, end, preserved) in preserved_spans {
        if start > pos {
            let before = &original_text[pos..start];
            let before_tokens = tokenize_simple(before);
            let before_tokens = post_process(before_tokens, config);
            result.extend(before_tokens);
        }
        result.push(preserved);
        pos = end;
    }

    if pos < original_text.len() {
        let remaining = &original_text[pos..];
        let remaining_tokens = tokenize_simple(remaining);
        let remaining_tokens = post_process(remaining_tokens, config);
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

pub(crate) fn post_process(tokens: Vec<String>, config: &TokenizerConfig) -> Vec<String> {
    post_process_with_preserved(tokens, config, None)
}

pub(crate) fn post_process_with_preserved(
    mut tokens: Vec<String>,
    config: &TokenizerConfig,
    preserve_chars: Option<&str>,
) -> Vec<String> {
    if config.lowercase {
        tokens = tokens.into_iter().map(|t| t.to_lowercase()).collect();
    }

    if config.remove_punctuation {
        tokens = tokens
            .into_iter()
            .map(|t| {
                t.chars()
                    .filter(|c| {
                        if let Some(preserved) = preserve_chars {
                            if preserved.contains(*c) {
                                return true;
                            }
                        }
                        !c.is_ascii_punctuation()
                    })
                    .collect()
            })
            .filter(|s: &String| !s.is_empty())
            .collect();
    }

    tokens
}