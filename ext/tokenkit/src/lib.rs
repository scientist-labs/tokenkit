mod config;
mod error;
mod tokenizer;

use config::{TokenizerConfig, TokenizerStrategy};
use error::TokenizerError;
use magnus::{define_module, function, Error, RArray, RHash, TryConvert};
use std::sync::Mutex;

// Store only the default configuration, not a tokenizer instance
static DEFAULT_CONFIG: Mutex<TokenizerConfig> = Mutex::new(TokenizerConfig {
    strategy: TokenizerStrategy::Unicode,
    lowercase: true,
    remove_punctuation: false,
    preserve_patterns: Vec::new(),
});

// Create a fresh tokenizer for each tokenize call
fn tokenize(text: String) -> std::result::Result<Vec<String>, Error> {
    // Get current default config
    let config = DEFAULT_CONFIG
        .lock()
        .map_err(|e| TokenizerError::MutexError(e.to_string()))?
        .clone();

    // Create fresh tokenizer from config
    let tokenizer = tokenizer::from_config(config)?;

    // Tokenize and return
    Ok(tokenizer.tokenize(&text))
}

// Configure sets the default configuration
fn configure(config_hash: RHash) -> std::result::Result<(), Error> {
    let config = parse_config_from_hash(config_hash)?;

    // Update default config
    let mut default = DEFAULT_CONFIG
        .lock()
        .map_err(|e| TokenizerError::MutexError(e.to_string()))?;
    *default = config;

    Ok(())
}

// Reset to factory defaults
fn reset() -> std::result::Result<(), Error> {
    let mut default = DEFAULT_CONFIG
        .lock()
        .map_err(|e| TokenizerError::MutexError(e.to_string()))?;
    *default = TokenizerConfig::default();
    Ok(())
}

// Get current default configuration
fn config_hash() -> std::result::Result<RHash, Error> {
    let config = DEFAULT_CONFIG
        .lock()
        .map_err(|e| TokenizerError::MutexError(e.to_string()))?
        .clone();

    config_to_hash(&config)
}

// Helper function to convert config to RHash
fn config_to_hash(config: &TokenizerConfig) -> std::result::Result<RHash, Error> {
    let hash = RHash::new();

    let strategy_str = match &config.strategy {
        TokenizerStrategy::Whitespace => "whitespace",
        TokenizerStrategy::Unicode => "unicode",
        TokenizerStrategy::Pattern { .. } => "pattern",
        TokenizerStrategy::Sentence => "sentence",
        TokenizerStrategy::Grapheme { .. } => "grapheme",
        TokenizerStrategy::Keyword => "keyword",
        TokenizerStrategy::EdgeNgram { .. } => "edge_ngram",
        TokenizerStrategy::Ngram { .. } => "ngram",
        TokenizerStrategy::PathHierarchy { .. } => "path_hierarchy",
        TokenizerStrategy::UrlEmail => "url_email",
        TokenizerStrategy::CharGroup { .. } => "char_group",
        TokenizerStrategy::Letter => "letter",
        TokenizerStrategy::Lowercase => "lowercase",
    };
    hash.aset("strategy", strategy_str)?;

    if let TokenizerStrategy::Pattern { regex } = &config.strategy {
        hash.aset("regex", regex.as_str())?;
    }

    if let TokenizerStrategy::Grapheme { extended } = &config.strategy {
        hash.aset("extended", *extended)?;
    }

    if let TokenizerStrategy::EdgeNgram { min_gram, max_gram } = &config.strategy {
        hash.aset("min_gram", *min_gram)?;
        hash.aset("max_gram", *max_gram)?;
    }

    if let TokenizerStrategy::PathHierarchy { delimiter } = &config.strategy {
        hash.aset("delimiter", delimiter.as_str())?;
    }

    if let TokenizerStrategy::Ngram { min_gram, max_gram } = &config.strategy {
        hash.aset("min_gram", *min_gram)?;
        hash.aset("max_gram", *max_gram)?;
    }

    if let TokenizerStrategy::CharGroup { split_on_chars } = &config.strategy {
        hash.aset("split_on_chars", split_on_chars.as_str())?;
    }

    hash.aset("lowercase", config.lowercase)?;
    hash.aset("remove_punctuation", config.remove_punctuation)?;

    let patterns = RArray::new();
    for pattern in &config.preserve_patterns {
        patterns.push(pattern.as_str())?;
    }
    hash.aset("preserve_patterns", patterns)?;

    Ok(hash)
}

// Parse config from Ruby hash
fn parse_config_from_hash(config_hash: RHash) -> std::result::Result<TokenizerConfig, Error> {
    let strategy_val = config_hash.get("strategy");
    let strategy = if let Some(val) = strategy_val {
        let strategy_str: String = TryConvert::try_convert(val)?;
        match strategy_str.as_str() {
            "whitespace" => TokenizerStrategy::Whitespace,
            "unicode" => TokenizerStrategy::Unicode,
            "pattern" => {
                let regex_val = config_hash
                    .get("regex")
                    .ok_or_else(|| {
                        TokenizerError::InvalidConfiguration(
                            "pattern strategy requires regex parameter".to_string()
                        )
                    })?;
                let regex: String = TryConvert::try_convert(regex_val)?;
                TokenizerStrategy::Pattern { regex }
            }
            "sentence" => TokenizerStrategy::Sentence,
            "grapheme" => {
                let extended_val = config_hash.get("extended");
                let extended = if let Some(val) = extended_val {
                    TryConvert::try_convert(val)?
                } else {
                    true
                };
                TokenizerStrategy::Grapheme { extended }
            }
            "keyword" => TokenizerStrategy::Keyword,
            "edge_ngram" => {
                let min_gram_val = config_hash.get("min_gram");
                let min_gram = if let Some(val) = min_gram_val {
                    TryConvert::try_convert(val)?
                } else {
                    2
                };
                let max_gram_val = config_hash.get("max_gram");
                let max_gram = if let Some(val) = max_gram_val {
                    TryConvert::try_convert(val)?
                } else {
                    10
                };
                TokenizerStrategy::EdgeNgram { min_gram, max_gram }
            }
            "path_hierarchy" => {
                let delimiter_val = config_hash.get("delimiter");
                let delimiter = if let Some(val) = delimiter_val {
                    TryConvert::try_convert(val)?
                } else {
                    "/".to_string()
                };
                TokenizerStrategy::PathHierarchy { delimiter }
            }
            "url_email" => TokenizerStrategy::UrlEmail,
            "ngram" => {
                let min_gram_val = config_hash.get("min_gram");
                let min_gram = if let Some(val) = min_gram_val {
                    TryConvert::try_convert(val)?
                } else {
                    2
                };
                let max_gram_val = config_hash.get("max_gram");
                let max_gram = if let Some(val) = max_gram_val {
                    TryConvert::try_convert(val)?
                } else {
                    10
                };
                TokenizerStrategy::Ngram { min_gram, max_gram }
            }
            "char_group" => {
                let split_on_chars_val = config_hash.get("split_on_chars");
                let split_on_chars = if let Some(val) = split_on_chars_val {
                    TryConvert::try_convert(val)?
                } else {
                    " \t\n\r".to_string()
                };
                TokenizerStrategy::CharGroup { split_on_chars }
            }
            "letter" => TokenizerStrategy::Letter,
            "lowercase" => TokenizerStrategy::Lowercase,
            _ => {
                return Err(TokenizerError::UnknownStrategy(strategy_str).into())
            }
        }
    } else {
        TokenizerStrategy::Unicode
    };

    let lowercase_val = config_hash.get("lowercase");
    let lowercase = if let Some(val) = lowercase_val {
        TryConvert::try_convert(val)?
    } else {
        true
    };

    let remove_punctuation_val = config_hash.get("remove_punctuation");
    let remove_punctuation = if let Some(val) = remove_punctuation_val {
        TryConvert::try_convert(val)?
    } else {
        false
    };

    let preserve_patterns_val = config_hash.get("preserve_patterns");
    let preserve_patterns = if let Some(val) = preserve_patterns_val {
        let array: RArray = TryConvert::try_convert(val)?;
        let mut patterns = Vec::new();
        for idx in 0..array.len() {
            let item = array.entry(idx as isize)?;
            let pattern_str: String = TryConvert::try_convert(item)?;
            patterns.push(pattern_str);
        }
        patterns
    } else {
        Vec::new()
    };

    let config = TokenizerConfig {
        strategy,
        lowercase,
        remove_punctuation,
        preserve_patterns,
    };

    // Validate the configuration
    validate_config(&config)?;

    Ok(config)
}

// Validate configuration parameters
fn validate_config(config: &TokenizerConfig) -> std::result::Result<(), TokenizerError> {
    use TokenizerStrategy::*;

    match &config.strategy {
        EdgeNgram { min_gram, max_gram } | Ngram { min_gram, max_gram } => {
            if *min_gram == 0 {
                return Err(TokenizerError::InvalidNgramConfig {
                    min: *min_gram,
                    max: *max_gram,
                });
            }
            if min_gram > max_gram {
                return Err(TokenizerError::InvalidNgramConfig {
                    min: *min_gram,
                    max: *max_gram,
                });
            }
        }
        PathHierarchy { delimiter } => {
            if delimiter.is_empty() {
                return Err(TokenizerError::EmptyDelimiter {
                    tokenizer: "PathHierarchy".to_string(),
                });
            }
        }
        Pattern { regex } => {
            // Validate regex pattern
            regex::Regex::new(regex).map_err(|e| TokenizerError::InvalidRegex {
                pattern: regex.clone(),
                error: e.to_string(),
            })?;
        }
        _ => {}
    }

    // Validate preserve patterns
    for pattern in &config.preserve_patterns {
        regex::Regex::new(pattern).map_err(|e| TokenizerError::InvalidRegex {
            pattern: pattern.clone(),
            error: e.to_string(),
        })?;
    }

    Ok(())
}

// Load config is just an alias for configure (for backward compat)
fn load_config(config_hash: RHash) -> std::result::Result<(), Error> {
    configure(config_hash)
}

// Tokenize with a specific config (creates fresh tokenizer)
fn tokenize_with_config(text: String, config_hash: RHash) -> std::result::Result<Vec<String>, Error> {
    let config = parse_config_from_hash(config_hash)?;

    // Create fresh tokenizer from config
    let tokenizer = tokenizer::from_config(config)?;

    // Tokenize and return
    Ok(tokenizer.tokenize(&text))
}

#[magnus::init]
fn init(_ruby: &magnus::Ruby) -> std::result::Result<(), Error> {
    let module = define_module("TokenKit")?;

    // Public API functions
    module.define_module_function("_tokenize", function!(tokenize, 1))?;
    module.define_module_function("_configure", function!(configure, 1))?;
    module.define_module_function("_reset", function!(reset, 0))?;
    module.define_module_function("_config_hash", function!(config_hash, 0))?;
    module.define_module_function("_load_config", function!(load_config, 1))?;

    // New instance-based function
    module.define_module_function("_tokenize_with_config", function!(tokenize_with_config, 2))?;

    Ok(())
}