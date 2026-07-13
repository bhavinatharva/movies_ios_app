# IPTV Project Development Rules

## Primary Goal
Always complete the requested task with the LOWEST possible cost (tokens, compute, time, and file analysis) while maintaining correctness.
Do NOT analyze or regenerate the entire project unless I explicitly request it.

## Context First
Before starting any task:
1. Read the existing `/docs` folder first.
2. Use the documentation as the primary source of project knowledge.
3. Only inspect additional Swift files if the documentation does not contain enough information.
4. Never re-analyze files that are unrelated to the current task.

## Documentation Rules
The `/docs` folder is the project's knowledge base.
Whenever code changes:
- Update only the affected documentation.
- Never regenerate every markdown file.
- Modify only documents impacted by the change.

## File Analysis Rules
For every task:
1. Determine which files are required.
2. Read only those files.
3. Avoid scanning unrelated folders.
4. Do not index the whole project.
5. Do not perform repository-wide searches unless absolutely necessary.
Always minimize file reads.

## Existing Knowledge
Assume previously generated documentation is correct unless the current task changes it.
Reuse existing knowledge instead of rediscovering it.

## Incremental Development
When implementing a feature:
- Reuse existing architecture.
- Reuse existing managers.
- Reuse existing services.
- Reuse existing models.
- Reuse existing utilities.
- Reuse existing components.
Avoid creating duplicate code.

## Documentation Updates
Only update documentation when necessary.
Examples:
- UI change → ScreenDocumentation.md
- New API → API.md
- New model → Models.md
- New service → Architecture.md + FileReference.md
- Player update → Player.md
Do not touch unrelated documents.

## Search Strategy
Always search in this order:
1. /docs
2. Relevant files
3. Related files
4. Entire project (only if required)
The entire project should be the last resort.

## Code Changes
When editing code:
Read only:
- the target file
- directly related files
- required interfaces/protocols
Avoid opening every ViewController, Model, Service, or Utility.

## Performance Rules
Always prefer:
- incremental analysis
- incremental documentation
- minimal file reads
- minimal token usage
- minimal code generation
- existing implementations
Never rewrite working code unnecessarily.

## Cost Optimization
For every request, ask internally: "What is the minimum number of files needed to complete this task correctly?"
Only inspect those files. Never analyze unrelated modules.

## Large Features
If a feature affects many modules:
1. Identify impacted files.
2. Read only impacted files.
3. Update only impacted docs.
4. Leave everything else untouched.

## Documentation Consistency
Keep documentation synchronized with code.
Never create duplicate information.
Always update existing markdown instead of creating redundant documents.

## Output Summary
After completing a task, report:
- Files read
- Files modified
- Documentation files updated
- New files created (if any)
- Why those files were necessary
Do not list unrelated files.

## Accuracy
Never assume. Never hallucinate. Never invent APIs, models, screens, services, or architecture.
Everything must be derived from either:
- existing documentation
- inspected source code

## Override Rule
Only perform a full project analysis if I explicitly request one with phrases such as:
- "analyze entire project"
- "regenerate all docs"
- "full project scan"
- "rebuild documentation"
Otherwise, always use the lowest-cost, incremental workflow.
