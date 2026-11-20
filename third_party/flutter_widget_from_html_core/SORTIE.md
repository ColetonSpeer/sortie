# flutter_widget_from_html_core 0.17.4 (vendored)

Unmodified copy of [flutter_widget_from_html_core 0.17.4](https://pub.dev/packages/flutter_widget_from_html_core/versions/0.17.4)
(without its example and tests) except for the table column widths in
`lib/src/widgets/html_table.dart`. Search for `Sortie patch`.

A table that has to fill a width (`width="100%"`, or any table under a
stretching parent, which is every table in a mail) had its columns split
equally before any content was measured. Mail templates put the text between
two 20px spacer cells and nest that two or three levels deep, so the text
ended up in a ninth or a twenty-seventh of the page and wrapped mid-word
(a Salesforce community notification, 2026-11-20).

The patch:

- keeps the equal split for single-column tables only;
- sizes the columns of other tables from their content, asking a cell that
  merely stretched to the table width for its intrinsic width instead;
- then grows the columns in proportion until the required width is filled.

Wired in through `dependency_overrides` in the root `pubspec.yaml`.
