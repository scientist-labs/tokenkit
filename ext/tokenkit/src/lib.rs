mod config;
mod tokenizer;

use config::{TokenizerConfig, TokenizerStrategy};
use magnus::{define_module, function, Error, RArray, RHash, TryConvert};
use std::cell::RefCell;
use tokenizer::Tokenizer;

thread_local! {
    static TOKENIZER: RefCell<Option<Box<dyn Tokenizer>>> = RefCell::new(None);
}

fn tokenize(text: String) -> Result<Vec<String>, Error> {
    TOKENIZER.with(|t| {
        let tokenizer = t.borrow();
        if let Some(ref tok) = *tokenizer {
            Ok(tok.tokenize(&text))
        } else {
            let default_config = TokenizerConfig::default();
            let tok = tokenizer::from_config(default_config)
                .map_err(|e| Error::new(magnus::exception::runtime_error(), e))?;
            let result = tok.tokenize(&text);
            Ok(result)
        }
    })
}

fn configure(config_hash: RHash) -> Result<(), Error> {
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
                        Error::new(
                            magnus::exception::arg_error(),
                            "pattern strategy requires regex parameter",
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
            _ => TokenizerStrategy::Unicode,
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
    let preserve_patterns: Vec<String> = if let Some(val) = preserve_patterns_val {
        let patterns_array: RArray = TryConvert::try_convert(val)?;
        patterns_array.to_vec()?
    } else {
        Vec::new()
    };

    let config = TokenizerConfig {
        strategy,
        lowercase,
        remove_punctuation,
        preserve_patterns,
    };

    let tokenizer = tokenizer::from_config(config)
        .map_err(|e| Error::new(magnus::exception::runtime_error(), e))?;

    TOKENIZER.with(|t| {
        *t.borrow_mut() = Some(tokenizer);
    });

    Ok(())
}

fn reset() -> Result<(), Error> {
    TOKENIZER.with(|t| {
        *t.borrow_mut() = None;
    });
    Ok(())
}

fn config_hash() -> Result<RHash, Error> {
    TOKENIZER.with(|t| {
        let tokenizer = t.borrow();
        if let Some(ref tok) = *tokenizer {
            let config = tok.config();
            let hash = RHash::new();

            let strategy_str = match &config.strategy {
                TokenizerStrategy::Whitespace => "whitespace",
                TokenizerStrategy::Unicode => "unicode",
                TokenizerStrategy::Pattern { .. } => "pattern",
                TokenizerStrategy::Sentence => "sentence",
                TokenizerStrategy::Grapheme { .. } => "grapheme",
                TokenizerStrategy::Keyword => "keyword",
                TokenizerStrategy::EdgeNgram { .. } => "edge_ngram",
                TokenizerStrategy::PathHierarchy { .. } => "path_hierarchy",
                TokenizerStrategy::UrlEmail => "url_email",
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

            hash.aset("lowercase", config.lowercase)?;
            hash.aset("remove_punctuation", config.remove_punctuation)?;

            let patterns = RArray::new();
            for pattern in &config.preserve_patterns {
                patterns.push(pattern.as_str())?;
            }
            hash.aset("preserve_patterns", patterns)?;

            Ok(hash)
        } else {
            let hash = RHash::new();
            hash.aset("strategy", "unicode")?;
            hash.aset("lowercase", true)?;
            hash.aset("remove_punctuation", false)?;
            hash.aset("preserve_patterns", RArray::new())?;
            Ok(hash)
        }
    })
}

fn load_config(config_hash: RHash) -> Result<(), Error> {
    configure(config_hash)
}

#[magnus::init]
fn init(_ruby: &magnus::Ruby) -> Result<(), Error> {
    let module = define_module("TokenKit")?;
    module.define_module_function("_tokenize", function!(tokenize, 1))?;
    module.define_module_function("_configure", function!(configure, 1))?;
    module.define_module_function("_reset", function!(reset, 0))?;
    module.define_module_function("_config_hash", function!(config_hash, 0))?;
    module.define_module_function("_load_config", function!(load_config, 1))?;
    Ok(())
}