### MultiMarkdown Quick Look with Style

<https://github.com/ttscoff/MMD-QuickLook>

[mmdql]: https://github.com/fletcher/MMD-QuickLook
[screenshot]: https://github.com/ttscoff/MMD-QuickLook/raw/master/MMDQLGithub-1.jpg

This is a quick fork of Fletcher Penney's [MMD Quicklook project][mmdql]. It adds some styling to the default Quick Look preview (based on GitHub CSS) and allows for customization via a `.mdqlstyle.css` file in your home folder.

![MultiMarkdown Quicklook with Style][screenshot]

To install, place the `MultiMarkdown QuickLook.qlgenerator` file in `~/Library/QuickLook/`. To make sure the Quick Look generator list reloads with the new file, you can run `qlmanage -r` on the command line.

To use a custom style, name the CSS file `.mdqlstyle.css` and place it in your User's home directory. Note the leading period. Default padding for the body class will be included before your styles, so you can pretty much drop in any CSS you want from any source. Use one of the provided files, copy CSS from your blog, your favorite website or build your own.

### Ready-made styles

A couple of default styles lifted from [Marked.app][marked].

* [Swiss](https://raw.github.com/ttscoff/MMD-QuickLook/master/mdqlstyle.swiss.css)
* [Upstanding Citizen](https://raw.github.com/ttscoff/MMD-QuickLook/master/mdqlstyle.upstandingcitizen.css) (includes custom fonts embedded in the CSS as data URIs)

[marked]: http://markedapp.com