# How to generate this website

This static documentation website is created by [MkDocs] and is using a theme from [bootswatch].

It uses "github pages" and this site is hosted by Github. The documentation source files are written in Markdown format.

With MkDocs tool, the generated site files (html files) are automatically pushed into a specific branch `gh-pages` of the git repository.

[MkDocs]: https://www.mkdocs.org
[bootswatch]: https://mkdocs.github.io/mkdocs-bootswatch/



## Installation

### 1. Install python and pip

[python and pip]

[python and pip]: https://realpython.com/installing-python/

### 2. Install mkdocs-bootswatch

``` bash
pip install mkdocs-bootswatch
```

Please refer to [bootswatch] for more information.

### 3. Install a markdown editor

You can simply edit the markdown (.md) files by any text editor, but it's better to user a professional markdown editor.

* [typora]. It supports all of the platforms (Windows/MacOS/Linux). Please configure typora to `strict` Markdown mode. That ensures you get the same output effects on both **typora** and **mkdocs**.

[typora]: https://typora.io/


* [vscode]. It's also a good editor and has abundant functions and extensions. You can install extensions of Markdown, Preview and Spell checker.

[vscode]: https://code.visualstudio.com/

### 4. Install other optional tools

* pdf2svg: This tool can convert a pdf lossless picture to svg format. For Mac OS, it can be easily installed by [Homebrew], simply by `brew install pdf2svg`.
* Alternative choice is [Inkscape] which is a free drawing tool and can help you draw and convert vector graphics.

[Homebrew]: https://brew.sh/
[Inkscape]: https://inkscape.org/

## Website Structure

First, you need to git clone the oc-accel repository and go to `web-doc` directory. Make sure you are working on a branch other than master.

``` bash
git clone git@github.com:OpenCAPI/oc-accel.git
git checkout <A branch other than master>
cd oc-accel/web-doc
```

The `docs` folder is where to put the markdown files, and the `mkdocs.yml` lists the website structure and global definitons. For example, this site has a structure like:

```
nav:
  - Home: 'index.md'
  - User Guide:
    - 'Prepare Environment': 'user-guide/prepare-env.md'
    - 'Run an example': 'user-guide/run-example.md'
    - 'Create a new action': 'user-guide/new-action.md'
    - 'Co-Simulation': 'user-guide/co-simulation.md'
    - 'FPGA Image build': 'user-guide/make-image.md'
    - 'Optimize HLS action': 'user-guide/optimize-hls.md'
    - 'Deploy on Power Server': 'user-guide/deploy.md'
    - 'Debug an issue': 'user-guide/debug-issue.md'
    - 'Command Reference': 'user-guide/command-reference.md'
  - Examples:
    - 'hdl_example': 'actions-doc/hdl-example.md'
    - 'hdl_helloworld': 'actions-doc/hdl-helloworld.md'
    - 'hls_helloworld': 'actions-doc/hls-helloworld.md'
    - 'hls_memcopy': 'actions-doc/hls-memcopy.md'
  - Deep Dive:
    - 'SNAP Software API': 'deep-dive/libosnap.md'
    - 'SNAP Registers': 'deep-dive/registers.md'
    - 'SNAP Logic Design': 'deep-dive/snap_core.md'
    - 'New Board Support': 'deep-dive/board-package.md'
  - Misc:
    - 'Document Guide': 'misc/doc-guide.md'
```

You can edit them as needed.

## Write Markdown pages

On your local desktop, edit markdown files under `web-doc/docs` folder. If you want to add/delete/rename the files, you also need to edit `mkdocs.yml`

Now it's time to work with an editor (i.e, typora) to write the documents. You also may need to learn some markdown syntax. Don't worry, that's easy. And please turn on the "spell checking" in your Markdown editor.

In your `terminal` (MacOS or Linux), or `cmd` (Windows), start a serve process:

``` bash
mkdocs serve
```

Then open a web browser, input <http://127.0.0.1:8000>. So whenever you save any markdown files, you can check the generated website immediately.



## Play with pictures

### The first rule

Reduce the usage of pictures. Avoid unnecessary screenshots.

### It's quite easy

You can insert jpg, png, svg files. You can also simply copy paste pictures from clipboard and paste them. Copy the files into a directory `./${filename}.assets`, and here `${filename}` is the name of markdown file. Use relative links in the document.

!!! note

    If you are using Typora, please enable "Copy images into ./${filename}.assets folder" in `Preferences` of typora.

### Tools to draw diagrams

You can take any drawing tools to create diagrams. You can save them as PNG format, but the better way is to save to SVG format.


For the diagrams from Microsoft PowerPoint, you can select the region of a diagram in PPT, `Ctrl-C` to copy it, and `Ctrl-V` to paste it in Typora directly. In this case, the diagram is saved as an PNG file.

But there is a better way to get the smallest file size and best quality:

- In PowerPoint, select the region of diagram, right-click mouse -> "Save as Picture ..." and save it as "PDF" format.
- Open the PDF file with [Inkscape]. (Right-click the file -> "Open with ...", choose Inkscape in the poped up list). Unclick "Embed images" and then "OK".
- In Inkscape, save it as SVG file.
- Insert the SVG file into Typora.

In my experiment, the PNG file is 188KB. But with the above flow to save it as SVG file, its size is 62KB. As a vectored diagram, it doesn't have any quality loss when zooming in.

!!! Warning

    Please use normal fonts in PPT, for example "Arial". Otherwise you may get a SVG file with a replaced font and that may look different.

## Code blocks and Admonitions

### Code blocks
Please assign the code language so it can be correctly rendered. For example ```` C` for C language.

``` C
// A function to implement bubble sort
void bubbleSort(int arr[], int n)
{
   int i, j;
   for (i = 0; i < n-1; i++)

       // Last i elements are already in place
       for (j = 0; j < n-i-1; j++)
           if (arr[j] > arr[j+1])
              swap(&arr[j], &arr[j+1]);
}
```


### Admonitions
You can use `!!! Note` or `!!! Warning` or `!!! Danger` to start a paragraph of admonitions. Then use 4 spaces to start the admonition text.

For example

```
!!! Danger "Error Message"

    This is a dangerous error.
```

It will be shown as:

!!! Danger "Error Message"

    This is a dangerous error.

## Deploy to Github Pages

When most of the edition work is done, and it's time to commit your documents to oc-accel github.

First, you should commit and push your changes of source files (in `web-doc`) to git repository. Create pull request, ask someone to review the documents, merge them into master branch after getting approvements.

Then you can simply publish website with just one step:

``` bash
cd <PATH>/oc-accel/web-doc
mkdocs gh-deploy
```

The entire website will be pushed to `gh-pages` branch of oc-snap repository. The documentation website will be available at <https://opencapi.github.io/oc-accel/>!

