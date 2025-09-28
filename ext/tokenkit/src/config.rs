use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct TokenizerConfig {
    pub strategy: TokenizerStrategy,
    pub lowercase: bool,
    pub remove_punctuation: bool,
    pub preserve_patterns: Vec<String>,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub enum TokenizerStrategy {
    Whitespace,
    Unicode,
    Pattern { regex: String },
    Sentence,
    Grapheme { extended: bool },
    Keyword,
    EdgeNgram { min_gram: usize, max_gram: usize },
    PathHierarchy { delimiter: String },
    UrlEmail,
}

impl Default for TokenizerConfig {
    fn default() -> Self {
        Self {
            strategy: TokenizerStrategy::Unicode,
            lowercase: true,
            remove_punctuation: false,
            preserve_patterns: Vec::new(),
        }
    }
}