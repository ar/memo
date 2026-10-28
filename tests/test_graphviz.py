"""Run with python3 -m unittest discover -s tests (requires pandoc and dot)."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


FILTER = Path(__file__).resolve().parents[1] / 'filters/graphviz.lua'
PANDOC = shutil.which('pandoc')


@unittest.skipUnless(PANDOC and shutil.which('dot'), 'requires pandoc and Graphviz')
class GraphvizTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def render(self, source, *, path=None, output='latex'):
        env = os.environ.copy()
        if path is not None:
            env['PATH'] = path
        return subprocess.run(
            [PANDOC, '-f', 'markdown', '-t', output, '--lua-filter', str(FILTER)],
            input=source, text=True, capture_output=True, cwd=self.root, env=env,
        )

    def test_vector_caption_and_dimensions(self):
        result = self.render('```{.dot #fig-test caption="A & B" width=95%}\n'
                             'digraph { A -> B }\n```\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(r'\begin{figure}', result.stdout)
        self.assertIn(r'\caption{A \& B}', result.stdout)
        self.assertIn(r'\label{fig-test}', result.stdout)
        self.assertIn(r'width=0.95\linewidth', result.stdout)
        pdfs = list((self.root / 'dot-img').glob('*.pdf'))
        self.assertEqual(len(pdfs), 1)
        self.assertTrue(pdfs[0].read_bytes().startswith(b'%PDF-'))
        if shutil.which('pdfimages'):
            images = subprocess.check_output(['pdfimages', '-list', str(pdfs[0])], text=True)
            self.assertEqual(len(images.strip().splitlines()), 2, images)

    def test_plain_fences_and_multiple_diagrams(self):
        result = self.render('```dot\ndigraph { A -> B }\n```\n\n'
                             '```dot\ndigraph { B -> C }\n```\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count(r'\includegraphics'), 2)
        self.assertNotIn(r'\caption', result.stdout)
        self.assertEqual(len(list((self.root / 'dot-img').glob('*.pdf'))), 2)

    def test_missing_dot_only_fails_for_dot_fences(self):
        result = self.render('```mermaid\ngraph LR; A-->B\n```\n', path=self.temp.name)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / 'dot-img').exists())
        result = self.render('```dot\ndigraph { A -> B }\n```\n', path=self.temp.name)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Install Graphviz (dot)', result.stderr)

    def test_invalid_dot_fails(self):
        result = self.render('```dot\nthis is not a graph\n```\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('check the diagram syntax', result.stderr)
        self.assertFalse((self.root / 'dot-img').exists())

    def test_other_formats_keep_source(self):
        result = self.render('```dot\ndigraph { A -> B }\n```\n',
                             output='html', path=self.temp.name)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('digraph', result.stdout)
        self.assertFalse((self.root / 'dot-img').exists())

    def test_legacy_filter_captions(self):
        # Reproduce mermaid-filter's output without launching a browser.
        producer = self.root / 'legacy.lua'
        producer.write_text('function CodeBlock(b) return pandoc.Para({'
                            'pandoc.Image("Mermaid caption", "diagram.png", "fig:")'
                            '}) end')
        result = subprocess.run(
            [PANDOC, '-f', 'markdown', '-t', 'latex',
             '--lua-filter', str(producer), '--lua-filter',
             str(FILTER.with_name('legacy-figures.lua'))],
            input='```mermaid\ngraph LR; A-->B\n```\n', text=True,
            capture_output=True, cwd=self.root,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(r'\caption{Mermaid caption}', result.stdout)
