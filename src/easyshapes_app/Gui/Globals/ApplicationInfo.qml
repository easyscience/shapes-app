// SPDX-FileCopyrightText: 2024 EasyApp contributors
// SPDX-License-Identifier: BSD-3-Clause
// © 2024 Contributors to the EasyApp project <https://github.com/easyscience/EasyApp>

pragma Singleton

import QtQuick

QtObject {

    readonly property var about: {
        'name': 'EasyPeasy',
        'namePrefix': 'Easy',
        'nameSuffix': 'Peasy',
        'namePrefixForLogo': 'easy',
        'nameSuffixForLogo': 'peasy',
        'homePageUrl': 'https://github.com/easyscience/peasy-app',
        'issuesUrl': 'https://github.com/easyscience/peasy-app/issues',
        'licenseUrl': 'https://github.com/easyscience/peasy-app/LICENCE',
        'dependenciesUrl': 'https://github.com/easyscience/peasy-app/DEPENDENCIES.md',
        'version': '0.1.0',
        'icon': Qt.resolvedUrl('../Resources/Logos/App.svg'),
        'date': new Date().toISOString().slice(0,10),
        'developerYearsFrom': '2019',
        'developerYearsTo': '2024',
        'description': 'EasyPeasy is a scientific software for performing imaginary calculations based on a theoretical model and refining its parameters against experimental data',
        'developerIcons': [
            {
                'url': 'https://ess.eu',
                'icon': Qt.resolvedUrl('../Resources/Logos/ESS.png'),
                'heightScale': 3.0
            }
        ]
    }

}

