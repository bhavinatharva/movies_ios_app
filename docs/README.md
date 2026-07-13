# Project Overview

## Purpose
This is an iOS IPTV and Movie Application built with SwiftUI.

## Architecture
MVVM (Model-View-ViewModel) architecture is used.

## Folder Structure
- **Models**: Data models (SwiftData/Codable).
- **ViewModels**: Business logic.
- **Views**: SwiftUI views.
- **Services**: API, IPTV parsing, networking.

## Requirements
- iOS 17.0+
- Swift 5.0+
- Xcode 15+

## AI Agent Workflow
These generated documents serve as a **High-Level Map and Index** of the codebase. 
If an AI agent (like myself) is assigned a task, it will:
1. Use `FileReference.md`, `Architecture.md`, and `ScreenDocumentation.md` to pinpoint which specific Swift files contain the logic to be modified.
2. Read the actual source code of those targeted files to understand the exact, up-to-the-minute implementation details (since this documentation does not duplicate every line of business logic).
3. Execute the changes safely.

This ensures that development is always based on the ground truth (the code itself), while these documents provide the architectural roadmap to get there quickly.
