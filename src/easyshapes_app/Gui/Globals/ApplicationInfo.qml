pragma Singleton

import QtQuick

QtObject {

    readonly property var about: {
        'name': 'EasyShapes',
        'namePrefix': 'Easy',
        'nameSuffix': 'Shapes',
        'namePrefixForLogo': 'easy',
        'nameSuffixForLogo': 'shapes',
        'homePageUrl': 'https://github.com/easyscience/shapes',
        'issuesUrl': 'https://github.com/easyscience/shapes/issues',
        'licenseUrl': 'https://github.com/easyscience/shapes/LICENCE',
        'dependenciesUrl': 'https://github.com/easyscience/shapes/DEPENDENCIES.md',
        'version': '0.1.0',
        'icon': Qt.resolvedUrl('../Resources/Logos/App.png'),
        'date': new Date().toISOString().slice(0,10),
        'developerYearsFrom': '2025',
        'developerYearsTo': '2026',
        'description': '**EasyShapes** is a scientific software for generation of ordered molecular aggregates and pre-assembled composite structures to seed molecular dynamics (MD) simulations aimed at studying equilibration (relaxation) processes in soft matter and biomolecular systems',
        'developerIcons': [
            {
                'url': 'https://ess.eu',
                'icon': Qt.resolvedUrl('../Resources/Logos/ESS.png'),
                'heightScale': 3.0
            }
        ]
    }

}

