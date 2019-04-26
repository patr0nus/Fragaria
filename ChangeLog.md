# MGSFragaria Release Notes

This document summarizes the major API history relative to this fork of Fragaria.

Similarly to the [Semantic Versioning Specification](https://semver.org), major API changes are performed only across major version number changes.


## Version 3.x

New features:

* Syntax highlighting can now apply additional attributes other than color --- namely *bold*, *italic* and *underline*.
* Improvements to the Colour Schemes infrastructure added in later versions of 2.x
  - All colour-scheme-related operations are now performed through the `MGSColourScheme` class
  - `MGSColourScheme` is easily extensible through subclassing to allow applying other attributes and font variants
* It is now possible to mix colour schemes in split views without glitches.
* New extensible parsing infrastructure
  - Replaces `SMLSyntaxColouringDelegate`, which has been removed
  - Allows customization of existing parsers through composition, similarly to what was possible through `SMLSyntaxColouringDelegate`
  - Provides an API for applications to implement new first-class parsers from scratch.
  - See the **Fragaria Simple** example application for details.
* The list of syntax colouring groups is now arbitrarily extensible by parsers.
  - Allows for more specific tags based on the language (for example, the `Instruction` and `Command` categories are less ambiguous now)
  - A hierarchical system allows old color schemes to be forwards-compatible
  - The built-in syntax definition format has been changed to take advantage of arbitrary syntax group names.


Other changes:

* Various improvements that reduce the size of the Fragaria framework for those projects that do not need the entirety of it:
  - The new preference panels are now split into a separate framework called `FragariaDefaultsCoordinator`
  - Most syntax definitions included in Fragaria are not included by default anymore in the base Framework; they are still supported and applications that need them can include them manually in their bundle.
* The built-in syntax definition file format has been changed to make the `SyntaxDefinitions.plist` file unnecessary
  - This makes it easier to include custom syntax definitions in an application.
* All Fragaria classes are now consistently prefixed `MGS`.


## Version 2.x

Version 2.x is a significant departure from the original design. The `MGSFragaria` class was replaced by `MGSFragariaView`, and the old preference panels were replaced by a more flexible design. The settings which could only be set as user defaults were converted to properties of `MGSFragariaView`, and `MGSTextMenuController` was removed (you can directly make a connection to `MGSFragariaView` or to First Responder instead).

Other new features include:

* Configurable breakpoint marks
* Syntax error badges and underlines
* Drag and drop
* Split view support


## Version 1.x (`legacy` branch)

This major version is compatible with the original API of the MGSFragaria project available (https://github.com/KosmicTask/Fragaria).
