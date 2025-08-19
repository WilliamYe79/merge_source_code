# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Zig command-line utility that merges source code files from a directory tree into a single output file with markdown formatting. The tool recursively scans directories, filters files by extension, and produces a consolidated view of the codebase.

## Common Commands

### Build and Run
- `zig build` - Build the project (creates both library and executable)
- `zig build -Doptimize=ReleaseFast` - Build optimized release version
- `zig build run` - Build and run the executable
- `zig build run -- -d <directory> -suffix <extensions>` - Run with arguments

### Testing
- `zig build test` - Run all unit tests (both library and executable tests)

### Installation
- `zig build install` - Install the executable to standard location

## Project Structure

The project follows standard Zig conventions:
- `build.zig` - Build configuration defining library, executable, and test targets
- `build.zig.zon` - Package manifest with metadata and dependencies
- `src/main.zig` - Main source file containing the complete implementation
- `README.md` - Comprehensive documentation and usage guide

## Architecture

The application is structured as a single-file implementation with these main components:

1. **Configuration Management** (`Config` struct) - Handles command-line arguments and settings
2. **File Collection** (`collectFiles` function) - Recursively scans directories and filters files
3. **Content Processing** (`writeMergedFile` function) - Merges files into markdown-formatted output
4. **Language Detection** (`getLanguageFromPath` function) - Maps file extensions to syntax highlighting languages

### Key Data Structures
- `FileEntry` - Represents a collected file with its relative path and content
- `Config` - Holds runtime configuration including root directory, file suffixes, and output settings

### Command-Line Interface
The tool accepts these arguments:
- `-d <directory>` - Root directory to scan (required)
- `-suffix <ext1,ext2,...>` - Comma-separated file extensions to include (required)
- `-encoding <encoding>` - Text encoding (optional, defaults to UTF-8)
- `-o <output_file>` - Output file path (optional, defaults to "merged_source_code.txt")

### Usage Examples
- `./zig-out/bin/merge_source_code -d ./src -suffix zig -o merged_zig_code.txt`
- `./zig-out/bin/merge_source_code -d ./project -suffix c,cpp,h -o combined_c_project.md`