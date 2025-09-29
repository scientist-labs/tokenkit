use thiserror::Error;

#[derive(Error, Debug)]
pub enum TokenizerError {
    #[error("Invalid configuration: {0}")]
    InvalidConfiguration(String),

    #[error("Invalid regex pattern '{pattern}': {error}")]
    InvalidRegex {
        pattern: String,
        error: String,
    },

    #[error("Invalid n-gram configuration: min_gram ({min}) must be > 0 and <= max_gram ({max})")]
    InvalidNgramConfig {
        min: usize,
        max: usize,
    },

    #[error("Empty delimiter is not allowed for {tokenizer} tokenizer")]
    EmptyDelimiter {
        tokenizer: String,
    },

    #[error("Unknown tokenizer strategy: {0}")]
    UnknownStrategy(String),

    #[error("Mutex lock failed: {0}")]
    MutexError(String),

    #[error("Ruby conversion error: {0}")]
    RubyConversionError(String),
}

impl From<TokenizerError> for magnus::Error {
    fn from(error: TokenizerError) -> Self {
        use magnus::exception;

        match error {
            TokenizerError::InvalidConfiguration(_) |
            TokenizerError::InvalidNgramConfig { .. } |
            TokenizerError::EmptyDelimiter { .. } |
            TokenizerError::UnknownStrategy(_) => {
                magnus::Error::new(exception::arg_error(), error.to_string())
            }
            TokenizerError::InvalidRegex { .. } => {
                magnus::Error::new(exception::regexp_error(), error.to_string())
            }
            TokenizerError::MutexError(_) => {
                magnus::Error::new(exception::runtime_error(), error.to_string())
            }
            TokenizerError::RubyConversionError(_) => {
                magnus::Error::new(exception::type_error(), error.to_string())
            }
        }
    }
}

// For converting magnus conversion errors to our error type
impl From<magnus::Error> for TokenizerError {
    fn from(error: magnus::Error) -> Self {
        TokenizerError::RubyConversionError(error.to_string())
    }
}

// Internal result type for Rust functions
pub type Result<T> = std::result::Result<T, TokenizerError>;