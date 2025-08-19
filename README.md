# Merge Source Code

A fast, lightweight command-line utility written in Zig that recursively merges source code files from a directory tree into a single markdown-formatted output file. Perfect for code reviews, documentation, or creating consolidated views of your codebase.

## Features

- **Recursive Directory Scanning**: Automatically traverses subdirectories to find all matching source files
- **Flexible File Filtering**: Filter files by extension using comma-separated lists (e.g., `c,cpp,h` or `js,ts,tsx`)
- **Markdown Output**: Generates properly formatted markdown with syntax highlighting for 25+ languages
- **Sorted Output**: Files are sorted alphabetically by path for consistent, predictable results
- **Lightweight & Fast**: Written in Zig for optimal performance and minimal resource usage
- **Cross-Platform**: Works on Linux, macOS, and Windows

## Installation

### Prerequisites

- [Zig](https://ziglang.org/) (latest version recommended)

### Build from Source

```bash
git clone <repository-url>
cd merge_source_code
zig build
```

### Install System-wide

```bash
zig build install
```

## Usage

```bash
./zig-out/bin/merge_source_code -d <directory> -suffix <extensions> [options]
```

### Required Arguments

- `-d <directory>`: Root directory to scan for source files
- `-suffix <ext1,ext2,...>`: Comma-separated list of file extensions to include (without dots)

### Optional Arguments

- `-o <output_file>`: Output file path (default: `merged_source_code.txt`)
- `-encoding <encoding>`: Text encoding (default: `UTF-8`)

### Examples

```bash
# Merge all Zig files from src directory
./zig-out/bin/merge_source_code -d ./src -suffix zig

# Merge C/C++ files with custom output name
./zig-out/bin/merge_source_code -d ./project -suffix c,cpp,h -o combined_c_project.md

# Merge multiple web technologies
./zig-out/bin/merge_source_code -d ./webapp -suffix js,ts,tsx,css,html -o webapp_source.md

# Merge Python project with custom encoding
./zig-out/bin/merge_source_code -d ./python_app -suffix py -encoding UTF-8 -o python_merged.txt
```

## Output Format

The tool generates markdown-formatted output with:

- File paths as headers
- Syntax-highlighted code blocks for each file
- Proper language detection based on file extensions
- Clean separation between files

Example output:
```markdown
src/main.zig:
```zig
const std = @import("std");
// ... file content
```

src/config.zig:
```zig
pub const Config = struct {
    // ... file content
};
```
```

## Supported Languages

The tool automatically detects and applies syntax highlighting for:

- **Systems**: C, C++, Rust, Zig, Go
- **Web**: JavaScript, TypeScript, HTML, CSS, SCSS
- **Scripting**: Python, Bash, Ruby, PHP, Lua
- **JVM**: Java, Kotlin, Gradle
- **Mobile**: Swift, Kotlin
- **Data**: JSON, YAML, TOML, XML, CSV, SQL
- **Config**: INI, Properties, Dockerfile
- **Documentation**: Markdown
- **Scientific**: R, MATLAB

## Development

### Build Commands

```bash
# Standard build
zig build

# Optimized release build
zig build -Doptimize=ReleaseFast

# Build and run
zig build run

# Build and run with arguments
zig build run -- -d ./src -suffix zig -o output.md
```

### Testing

```bash
# Run all unit tests
zig build test
```

## Project Structure

```
├── build.zig          # Build configuration
├── build.zig.zon      # Package manifest
├── src/
│   └── main.zig       # Complete implementation
├── CLAUDE.md          # AI assistant guidance
└── README.md          # This file
```

## Architecture

The application consists of several key components:

- **Config Management**: Handles command-line argument parsing and validation
- **File Collection**: Recursively scans directories and filters files by extension
- **Content Processing**: Reads file contents and formats them as markdown
- **Language Detection**: Maps file extensions to syntax highlighting languages

## License

This project is open source. See the license file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Changelog

### v0.0.0
- Initial release
- Basic directory scanning and file merging functionality
- Support for 25+ programming languages
- Markdown output with syntax highlighting
