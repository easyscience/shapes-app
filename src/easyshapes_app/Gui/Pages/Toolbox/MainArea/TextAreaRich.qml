// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

import QtQuick
import QtGraphs

import EasyApp.Gui.Style as EaStyle
import EasyApp.Gui.Elements as EaElements

import Gui.Globals as Globals


EaElements.TextArea {
    textFormat: TextEdit.RichText

    text: '<p>
  <strong>Lorem ipsum</strong> dolor sit amet, consectetur adipiscing elit,
  sed do eiusmod tempor incididunt ut labore et dolore<br> magna aliqua.
  <em>Ut enim ad minim veniam</em>, quis nostrud exercitation ullamco laboris
  nisi ut aliquip ex ea<br> commodo consequat.
</p>

<p>
  Duis aute irure dolor in <span style="text-decoration: underline;">
  reprehenderit</span> in voluptate velit esse cillum dolore eu fugiat
  nulla pariatur.<br>
  <strong>Excepteur sint occaecat</strong> cupidatat non proident, sunt in
  culpa qui officia deserunt mollit anim id est laborum.
</p>'
}
