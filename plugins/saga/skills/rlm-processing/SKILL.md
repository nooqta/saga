---
description: "Process large codebases using Recursive Language Model patterns. Use when context exceeds 50K tokens or requires deep multi-file analysis."
capabilities: ["large-codebase-processing", "context-chunking", "semantic-analysis", "pattern-discovery", "cost-optimization"]
---

# RLM Processing Skill

Expert guidance for analyzing large codebases programmatically.

## When to Use

- Context exceeds 50K tokens
- Analysis spans >5 interconnected files
- Pattern discovery across unfamiliar codebase
- Cross-cutting concerns (auth, logging, error handling)

## Core Concept

Instead of loading massive context directly:
1. Load files as variables
2. Write code to chunk, filter, process
3. Use `llm_query()` for semantic tasks
4. Aggregate results incrementally
5. Return condensed findings

## Available Environment

```python
# Variables
context         # Dict: file path → content
total_chars     # Total characters
total_tokens    # Estimated tokens (~chars/4)

# Functions
llm_query(prompt)    # Semantic analysis
print(text)          # View output (truncated)
FINAL(answer)        # Return text answer
FINAL_VAR(var_name)  # Return variable
```

## Processing Strategy

### Phase 1: Probe
Understand what you're working with:
```python
print(f"Files: {len(context)}")
print(f"Size: ~{total_tokens:,} tokens")
sample = list(context.keys())[0]
print(context[sample][:2000])
```

### Phase 2: Filter
Reduce to relevant subset:
```python
relevant = {k: v for k, v in context.items()
            if 'auth' in k.lower()}
```

### Phase 3: Chunk
Split by logical boundaries:
```python
def chunk_by_functions(code):
    import re
    pattern = r'(export\s+)?(async\s+)?(function|class)\s+'
    return re.split(pattern, code)
```

### Phase 4: Analyze
Code-based for syntax, LLM for semantics:
```python
# Code: Find patterns
imports = re.findall(r'import.*from [\'"]([^\'"]+)', content)

# LLM: Understand purpose
purpose = llm_query(f"What does this do?\n{chunk[:2000]}")
```

### Phase 5: Aggregate
Build answer incrementally:
```python
findings = []
for path, content in relevant.items():
    # ... analysis
    findings.append(f"{path}: {summary}")
```

### Phase 6: Return
```python
result = {
    "analysis": "Summary",
    "relevant_files": files,
    "code_patterns": patterns,
    "implementation_hints": hints
}
FINAL_VAR('result')
```

## Chunking Strategies

### By Function/Class
```python
import re
def chunk_functions(code):
    pattern = r'((?:export\s+)?(?:async\s+)?(?:function|class|const\s+\w+\s*=)\s+[^{]*\{)'
    return re.split(pattern, code)
```

### By Size
```python
def chunk_by_size(text, max_chars=5000):
    chunks = []
    current = ""
    for line in text.split('\n'):
        if len(current) + len(line) > max_chars:
            chunks.append(current)
            current = line
        else:
            current += '\n' + line
    if current:
        chunks.append(current)
    return chunks
```

### By Logical Section
```python
def chunk_by_section(code):
    # Split on blank lines or comment blocks
    return re.split(r'\n\n+', code)
```

## Common Queries

### Find API Endpoints
```python
endpoints = []
for path, content in context.items():
    rest = re.findall(
        r'(app|router)\.(get|post|put|delete)\([\'"]([^\'"]+)',
        content
    )
    endpoints.extend(rest)
```

### Find Authentication Pattern
```python
auth_files = [p for p in context if 'auth' in p.lower()]
for path in auth_files[:5]:
    role = llm_query(f"Role in auth?\n{context[path][:3000]}")
```

### Find Error Handling
```python
error_files = []
for path, content in context.items():
    if re.search(r'catch\s*\(|\.catch\(|handleError', content):
        error_files.append(path)
```

### Map Data Flow
```python
# Find where data enters
inputs = re.findall(r'req\.(body|params|query)', content)

# Find where it's saved
saves = re.findall(r'\.(save|create|insert|update)\(', content)
```

## Cost Optimization

### Do with Code
- String/regex patterns
- Counting occurrences
- File path filtering
- Extracting structured data

### Do with llm_query
- Semantic understanding
- Classification
- Summarization
- Complex patterns

### Limits
- Max ~20 llm_query() calls per session
- Each prompt < 2000 tokens
- Always filter first, then analyze

## Output Format

```json
{
  "analysis": "Condensed findings",
  "relevant_files": ["src/foo.ts"],
  "code_patterns": ["Pattern 1", "Pattern 2"],
  "implementation_hints": "Recommendations",
  "tokens_processed": 150000,
  "sub_calls_made": 12
}
```

## Best Practices

1. **Start broad, narrow down**: Probe → Filter → Analyze
2. **Code first**: Try regex before LLM
3. **Sample first**: Test on subset before full run
4. **Track costs**: Count llm_query calls
5. **Return structure**: Always JSON for downstream use
