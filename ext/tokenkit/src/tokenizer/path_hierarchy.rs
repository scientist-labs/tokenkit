use super::{post_process_with_preserved, BaseTokenizerFields, Tokenizer};
use crate::config::TokenizerConfig;

pub struct PathHierarchyTokenizer {
    base: BaseTokenizerFields,
    delimiter: String,
}

impl PathHierarchyTokenizer {
    pub fn new(config: TokenizerConfig, delimiter: String) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
            delimiter,
        }
    }

    fn generate_hierarchy(&self, path: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let parts: Vec<&str> = path.split(&self.delimiter).collect();

        let mut current_path = String::new();
        let starts_with_delimiter = path.starts_with(&self.delimiter);

        for part in parts.iter() {
            if part.is_empty() {
                continue;
            }

            if !current_path.is_empty() {
                current_path.push_str(&self.delimiter);
            } else if starts_with_delimiter {
                current_path.push_str(&self.delimiter);
            }

            current_path.push_str(part);
            tokens.push(current_path.clone());
        }

        tokens
    }

    fn apply_patterns_to_hierarchy(&self, text: &str) -> Vec<String> {
        if self.base.preserve_patterns().is_empty() {
            return self.generate_hierarchy(text);
        }

        // Generate all hierarchical tokens first
        let all_tokens = self.generate_hierarchy(text);

        // Find which tokens are completely matched by preserve patterns
        let mut preserved_tokens = Vec::new();
        for token in &all_tokens {
            for pattern in self.base.preserve_patterns() {
                if let Some(mat) = pattern.find(token) {
                    if mat.as_str() == token {
                        preserved_tokens.push(token.clone());
                        break;
                    }
                }
            }
        }

        // Now build the result, applying lowercase where appropriate
        let mut result = Vec::new();
        for token in all_tokens {
            // Check if this token should be included
            // Include if: it's a preserved token OR it extends beyond a preserved token
            let mut should_include = false;
            let mut apply_lowercase = self.base.config.lowercase;

            if preserved_tokens.contains(&token) {
                should_include = true;
                apply_lowercase = false; // Don't lowercase preserved tokens
            } else {
                // Check if this token extends a preserved token
                let mut extends_preserved = false;
                for preserved in &preserved_tokens {
                    if token.starts_with(preserved) && token.len() > preserved.len() {
                        extends_preserved = true;
                        break;
                    }
                }

                if extends_preserved {
                    should_include = true;
                } else {
                    // Include if no preserved token is a prefix of this one
                    let mut has_preserved_prefix = false;
                    for preserved in &preserved_tokens {
                        if preserved.starts_with(&token) && preserved != &token {
                            has_preserved_prefix = true;
                            break;
                        }
                    }
                    should_include = !has_preserved_prefix;
                }
            }

            if should_include {
                if apply_lowercase && !preserved_tokens.contains(&token) {
                    // Apply lowercase to non-preserved parts
                    let mut lowercased = String::new();
                    let starts_with_delim = token.starts_with(&self.delimiter);
                    let parts: Vec<&str> = token.split(&self.delimiter).collect();

                    for (i, part) in parts.iter().enumerate() {
                        if part.is_empty() {
                            if i == 0 && starts_with_delim {
                                // Path starts with delimiter, add it once
                                lowercased.push_str(&self.delimiter);
                            }
                            continue;
                        }

                        if i > 0 || (i == 0 && starts_with_delim) {
                            if !lowercased.is_empty() && !lowercased.ends_with(&self.delimiter) {
                                lowercased.push_str(&self.delimiter);
                            }
                        }

                        // Check if this specific part should be preserved
                        let mut preserve_part = false;
                        for pattern in self.base.preserve_patterns() {
                            if pattern.is_match(part) {
                                preserve_part = true;
                                break;
                            }
                        }

                        if preserve_part {
                            lowercased.push_str(part);
                        } else {
                            lowercased.push_str(&part.to_lowercase());
                        }
                    }
                    result.push(lowercased);
                } else {
                    result.push(token);
                }
            }
        }

        result
    }
}

impl Tokenizer for PathHierarchyTokenizer {
    fn tokenize(&self, text: &str) -> Vec<String> {
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return vec![];
        }

        if self.base.has_preserve_patterns() {
            let mut tokens = self.apply_patterns_to_hierarchy(trimmed);

            // Apply remove_punctuation if needed (but preserve delimiters)
            if self.base.config.remove_punctuation {
                tokens = tokens.into_iter().map(|token| {
                    let parts: Vec<&str> = token.split(&self.delimiter).collect();
                    let processed: Vec<String> = parts.iter().map(|part| {
                        if part.is_empty() {
                            String::new()
                        } else {
                            // Check if this part should be preserved
                            let should_preserve = self.base.preserve_patterns().iter().any(|p| p.is_match(part));
                            if should_preserve {
                                part.to_string()
                            } else {
                                part.chars()
                                    .filter(|c| !c.is_ascii_punctuation() || self.delimiter.contains(*c))
                                    .collect()
                            }
                        }
                    }).collect();
                    processed.join(&self.delimiter)
                }).filter(|s| !s.is_empty() && s != &self.delimiter).collect();
            }

            tokens
        } else {
            let tokens = self.generate_hierarchy(trimmed);
            post_process_with_preserved(tokens, &self.base.config, Some(&self.delimiter))
        }
    }

}