# Code style

- Use `freedesktop-sdk` v25.08 for the `freedesktop-sdk` junction element.
- Use `Xvfb` inside the BuildStream sandbox to run the Wine commands with Proton-GE.
- When running Proton, you should use the `wine` executable directly.

# Workflow

- Be sure to commit after each change, so its easily diffable.
- Write down notes as you go.
- Make sure commits are isolated to each group of changes, and working to keep the diff small.
