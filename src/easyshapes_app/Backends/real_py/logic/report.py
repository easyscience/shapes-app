# SPDX-FileCopyrightText: 2021-2026 EasyPeasy contributors <https://github.com/easyscience>
# SPDX-License-Identifier: BSD-3-Clause


def outline(serialized):
    """
    An item as to_dict serializes it, as an indented text tree.

    An item is a line with its class, its attributes one level deeper,
    its name first; a list's members follow as '- ' lines, a dict's as
    'key: ' lines; any other value shows as it is. The type, module and
    uid of each value are left out.
    """
    return '\n'.join(_lines(serialized, '', 0))


def _lines(node, label, depth):
    indent = '  ' * depth
    data = node['data']
    # Only an item carries a uid
    if 'id' in node:
        yield f'{indent}{label}{node["dtype"]}'
        # to_dict puts the name last, after the sorted attributes
        attributes = sorted(data.items(), key=lambda attribute: attribute[0] != 'name')
        members = ((f'{key}: ', value) for key, value in attributes)
    elif isinstance(data, (list, dict)):
        if not data:
            yield f'{indent}{label}{data}'
            return
        yield f'{indent}{label}'.rstrip()
        members = (
            ((f'{key}: ', value) for key, value in data.items())
            if isinstance(data, dict)
            else (('- ', member) for member in data)
        )
    else:
        yield f'{indent}{label}{data}'
        return
    for member_label, member in members:
        yield from _lines(member, member_label, depth + 1)
