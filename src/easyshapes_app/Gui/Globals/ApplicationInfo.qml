pragma Singleton

import QtQuick

QtObject {

    readonly property var about: {
        'name': 'EasyShapes',
        'namePrefix': 'Easy',
        'nameSuffix': 'Shapes',
        'namePrefixForLogo': 'easy',
        'nameSuffixForLogo': 'shapes',
        'homePageUrl': 'https://easyscience.github.io/shapes-app/',
        // Deep links need the version folder: dev/ until the first
        // release, latest/ after it
        'docsUrl': 'https://easyscience.github.io/shapes-app/dev/',
        'discussionsUrl': 'https://github.com/easyscience/shapes/discussions',
        'issuesUrl': 'https://github.com/easyscience/shapes-app/issues',
        'licenseUrl': 'https://github.com/easyscience/shapes-app/blob/master/LICENSE',
        // develop until the first release puts the file on master
        'dependenciesUrl': 'https://github.com/easyscience/shapes-app/blob/develop/DEPENDENCIES.md',
        'version': '0.1.0',
        'icon': Qt.resolvedUrl('../Resources/Logos/App.png'),
        'date': new Date().toISOString().slice(0,10),
        'developerYearsFrom': '2025',
        'developerYearsTo': '2026',
        'description': '<b>EasyShapes</b> is a scientific software for generation of ordered<br>'
                       + 'molecular aggregates and pre-assembled composite structures to seed<br>'
                       + 'molecular dynamics (MD) simulations aimed at studying equilibration<br>'
                       + '(relaxation) processes in soft matter and biomolecular systems.',
        'developerIcons': [
            {
                'url': 'https://ess.eu',
                'icon': Qt.resolvedUrl('../Resources/Logos/ESS.png'),
                'heightScale': 3.0
            }
        ]
    }

}

