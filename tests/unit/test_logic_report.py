# SPDX-FileCopyrightText: 2025-2026 EasyShapes contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause

from easyshapes_app.Backends.real_py.logic.report import outline


def value(data, dtype='str'):
    """
    A value as to_dict serializes it.
    """
    return {'dtype': dtype, 'data': data, 'module': 'builtins'}


def item(dtype, **attributes):
    """
    An item as to_dict serializes it.
    """
    return {'module': 'shapes.project', 'dtype': dtype, 'data': attributes, 'id': 'uid'}


def test_an_item_shows_its_class_and_its_attributes_nested_name_first():
    # As to_dict orders them: sorted, the name last
    serialized = item(
        'Project',
        analysis=value(None, 'NoneType'),
        salts=value([], 'list'),
        sample_model=item(
            'SampleModel',
            components=value([item('Component', name=value('SDS')), value(38, 'int')], 'list'),
            ranges=value({'min': value(0.5, 'float')}, 'dict'),
        ),
        name=value('ring1'),
    )

    assert outline(serialized).split('\n') == [
        'Project',
        '  name: ring1',
        '  analysis: None',
        '  salts: []',
        '  sample_model: SampleModel',
        '    components:',
        '      - Component',
        '        name: SDS',
        '      - 38',
        '    ranges:',
        '      min: 0.5',
    ]
