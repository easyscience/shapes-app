// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

// Mirrors Backend.report: the Summary page's text, the project as an
// outline of what its save writes, read again by refresh. The mock's is
// a fixed example, and it never fails.
QtObject {
    // Why the project can't be outlined; '' when it can
    readonly property string error: ''

    readonly property string text: 'Project
  name: ring1
  description: An SDS ring
  sample_model: SampleModel
    name: ring1
    structure: Ring
      name: None
      components: Components
        name: None
        items:
          - Component
            name: SDS
            mint: 38
            mext: 4
            paths:
              - /home/user/Projects/ring1/Component/SDS/SDS.itp
              - /home/user/Projects/ring1/Component/SDS/SDS.gro
      count: 12
      radius: 2.5
    buffer: Buffer
      solvent: Solvent
        name: TIP3
      components: []
  analysis: Analysis
    equilibration: Equilibration
      first_stage: 0
      last_stage: None
      threads: None
      restrain_to_box_center: False'

    function refresh() {}
}
