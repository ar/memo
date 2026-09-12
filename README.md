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

To use the previous double-column style:

```sh
memo --template custom_eisvogel file.md double
```

For direct Pandoc use, also pass `-V classoption=twocolumn
-M memo-magazine:true --lua-filter=/path/to/filters/magazine.lua`.
