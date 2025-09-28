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

impl TokenizerConfig {
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }

    pub fn from_json(json: &str) -> Result<Self, serde_json::Error> {
        serde_json::from_str(json)
    }
}