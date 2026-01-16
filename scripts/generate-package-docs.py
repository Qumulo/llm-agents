#!/usr/bin/env python3
"""Generate markdown documentation for all packages and update README.md."""

import json
import subprocess
import sys
from pathlib import Path

# Markers for the generated section in README.md
BEGIN_MARKER = "<!-- BEGIN GENERATED PACKAGE DOCS -->"
END_MARKER = "<!-- END GENERATED PACKAGE DOCS -->"


def get_all_packages_metadata() -> dict[str, dict[str, str | bool | None]]:
    """Get metadata for all packages using a single nix eval."""
    nix_file = Path(__file__).parent / "generate-package-docs.nix"

    try:
        result = subprocess.run(
            [
                "nix",
                "eval",
                "--json",
                "--file",
                str(nix_file),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error running nix eval: {e}", file=sys.stderr)
        if e.stderr:
            print(f"stderr: {e.stderr}", file=sys.stderr)
        raise

    data = json.loads(result.stdout)
    # Filter out null values (packages that failed to evaluate)
    return {k: v for k, v in data.items() if v is not None}


MAX_DESCRIPTION_LENGTH = 80


def generate_package_row(package: str, metadata: dict[str, str | bool | None]) -> str:
    """Generate a table row for a package."""
    description = metadata.get("description", "No description available")
    # Truncate long descriptions for table readability
    if len(description) > MAX_DESCRIPTION_LENGTH:
        description = description[: MAX_DESCRIPTION_LENGTH - 3] + "..."
    license_info = metadata.get("license", "Check package")
    homepage = metadata.get("homepage", "")
    pkg_link = f"[{package}](packages/{package}/package.nix)"
    if homepage:
        pkg_link = f"[{package}]({homepage})"
    return f"| {pkg_link} | {description} | {license_info} |"


# Define category order for display
CATEGORY_ORDER = [
    "AI Coding Agents",
    "AI Assistants",
    "Claude Code Ecosystem",
    "ACP Ecosystem",
    "MCP",
    "Usage Analytics",
    "Workflow & Project Management",
    "Code Review",
    "Utilities",
    "Uncategorized",
]


def generate_category_table(
    category: str, packages: list[tuple[str, dict]]
) -> list[str]:
    """Generate a markdown table for a category of packages."""
    lines = [
        f"### {category}",
        "",
        "| Package | Description | License |",
        "|---------|-------------|---------|",
    ]
    for package, metadata in packages:
        lines.append(generate_package_row(package, metadata))
    return lines


def generate_all_docs() -> str:
    """Generate documentation for all packages, grouped by category."""
    all_metadata = get_all_packages_metadata()

    # Group packages by category
    by_category: dict[str, list[tuple[str, dict]]] = {}
    for package in sorted(all_metadata.keys()):
        metadata = all_metadata[package]
        category = metadata.get("category", "Uncategorized")
        if category not in by_category:
            by_category[category] = []
        by_category[category].append((package, metadata))

    docs: list[str] = []

    # Output categories in defined order, then any remaining
    seen_categories: set[str] = set()
    for category in CATEGORY_ORDER:
        if category in by_category:
            seen_categories.add(category)
            docs.extend(generate_category_table(category, by_category[category]))
            docs.append("")  # Add spacing between categories

    # Handle any categories not in CATEGORY_ORDER
    for category in sorted(by_category.keys()):
        if category not in seen_categories:
            docs.extend(generate_category_table(category, by_category[category]))
            docs.append("")

    return "\n".join(docs).rstrip()


def update_readme(readme_path: Path) -> bool:
    """Update README.md with generated package documentation.

    Returns True if the file was modified, False otherwise.
    """
    content = readme_path.read_text()

    # Find the markers
    begin_idx = content.find(BEGIN_MARKER)
    end_idx = content.find(END_MARKER)

    if begin_idx == -1 or end_idx == -1:
        print(f"Error: Could not find markers in {readme_path}", file=sys.stderr)
        print(f"  Expected: {BEGIN_MARKER}", file=sys.stderr)
        print(f"  And: {END_MARKER}", file=sys.stderr)
        sys.exit(1)

    if end_idx < begin_idx:
        print("Error: END marker appears before BEGIN marker", file=sys.stderr)
        sys.exit(1)

    # Generate new content
    generated_docs = generate_all_docs()

    # Build new file content
    new_content = (
        content[: begin_idx + len(BEGIN_MARKER)]
        + "\n\n"
        + generated_docs
        + "\n"
        + content[end_idx:]
    )

    if new_content == content:
        return False

    readme_path.write_text(new_content)
    return True


def main() -> None:
    """Run the main documentation generation process."""
    # Find README.md relative to this script
    script_dir = Path(__file__).parent
    readme_path = script_dir.parent / "README.md"

    if not readme_path.exists():
        print(f"Error: README.md not found at {readme_path}", file=sys.stderr)
        sys.exit(1)

    modified = update_readme(readme_path)
    if modified:
        print(f"Updated {readme_path}")
    else:
        print(f"No changes to {readme_path}")


if __name__ == "__main__":
    main()
