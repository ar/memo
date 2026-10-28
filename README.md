[PDF](./memomemo.pdf), [SRC](./memomemo.md).
## Magazine layout

`memo file.md double` selects `custom_magazine`, a two-column Eisvogel
 derivative with TeX Gyre Pagella body text, sans-serif headings, 19 mm margins,
an 8 mm gutter, compact paragraphs, and a full-width article title.
`memo file.md single` retains `custom_eisvogel`.

Install `custom_magazine.latex` alongside `custom_eisvogel.latex` in the Pandoc
user data directory's `templates/` folder, and `filters/magazine.lua` in its
`filters/` folder. The template source is maintained in
`~/git/dotfiles/pandoc/templates/custom_magazine.latex`.

A leading H1 becomes the title when no YAML title is provided. Its link target
is retained and remaining headings move up one level. Explicit YAML titles
leave body headings unchanged. Horizontal rules become short editorial rules.
These transformations run only when memo selects `custom_magazine`.

Optional YAML settings:

```yaml
---
title: Article title
subtitle: A short introductory deck
author: Author name
magazine-running-title: Short title for the running header
column-sep: 8mm
column-rule: 0pt
fontsize: 10pt
linestretch: 1.08
---
```

The template uses XeLaTeX and TeX Live fonts. It is intended for articles,
not books or slides. It uses an inline title instead of a separate cover;
`titlepage` options do not create a cover. Existing table handling is unchanged:
tables span both columns using the installed `twocolumn-tables.lua` filter,
with its existing caption and multipage limitations.

### Mixing one- and two-column pages

Put `\onecolumn` or `\twocolumn` on a line of its own to switch layout for
the pages that follow; each switch starts a new page. Typical use: a two-column
introduction, then `\onecolumn` before reference sections with wide code
blocks and tables, and `\twocolumn` to return. Tables in one-column regions
render inline as usual; only tables in two-column regions are turned into
spanning floats.

To use the previous double-column style:

```sh
memo --template custom_eisvogel file.md double
```

For direct Pandoc use, also pass `-V classoption=twocolumn
-M memo-magazine:true --lua-filter=/path/to/filters/magazine.lua`.

### Graphviz (optional)

Install Graphviz (`brew install graphviz` on macOS, or `apt install graphviz`
on Debian/Ubuntu) and copy the filter into the Pandoc user data directory:

```sh
mkdir -p ~/.local/share/pandoc/filters
cp filters/graphviz.lua filters/legacy-figures.lua ~/.local/share/pandoc/filters/
```

Use a `dot` fenced code block for a vector diagram. Add fence attributes for
a numbered caption and image dimensions:

```{.dot #fig-architecture caption="Proposed logical architecture" width=95%}
digraph architecture {
  rankdir=LR;
  Client -> Gateway -> Service;
}
```

`caption` supplies the numbered “Figure N” caption, `width` and optional
`height` use Pandoc image dimensions (such as `95%` or `10cm`), and an optional
`#identifier` supplies the figure's link target. A plain `dot` fence also
works, without a caption. Captions are plain text.

The filter runs `dot -Tpdf` for LaTeX/PDF output, preserving vector text and
lines. Other output formats leave the code block unchanged. Generated PDFs
live in `dot-img/` beside the output document; memo removes that directory
on success or failure. `--keep` retains it, and `--clean` removes it. No
additional `.gitignore` entry is needed when `*.pdf` is already ignored.

`memo --doctor` reports Graphviz as optional. Only a document containing a
`dot` fence needs `dot`; a missing executable or invalid diagram fails the
build with a diagnostic. Mermaid fences continue to use `mermaid-filter`.
The companion `legacy-figures.lua` filter preserves numbered captions from
older external filters such as `mermaid-filter` when using Pandoc 3.
