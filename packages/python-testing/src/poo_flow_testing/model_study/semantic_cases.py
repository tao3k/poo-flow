# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Current semantic ABI tasks, independent of historical paid-study plans."""
from copy import deepcopy


def corpus():
    task = {'lens': {'generation': 1, 'clock': 'clock', 'start': 0, 'end': 10,
                     'asOf': 10, 'cut': 'cut', 'members': ['a', 'b', 'c'],
                     'horizon': 8, 'closed': True},
            'source': {'identity': 'source', 'generation': 1, 'clock': 'clock',
                       'events': [['a', 1, 1], ['b', 2, 2], ['c', 3, 3]],
                       'parents': [['a', 'b'], ['b', 'c']]}, 'root': 'a'}
    cases = []
    for name in ['chain', 'branch', 'withdrawal', 'open-cut', 'late-ingestion',
                 'interval', 'zero-horizon', 'one-horizon', 'clock-mismatch',
                 'generation-mismatch', 'window-end', 'unknown-time']:
        item = deepcopy(task)
        if name == 'branch':
            item['source']['parents'] = [['a', 'b'], ['a', 'c']]
        elif name == 'withdrawal':
            item['source']['parents'] = []
        elif name == 'open-cut':
            item['lens']['closed'] = False
        elif name == 'late-ingestion':
            item['lens']['asOf'] = 1
        elif name == 'interval':
            item['source']['events'][1][1] = ['between', 0, 20]
        elif name == 'zero-horizon':
            item['lens']['horizon'] = 0
        elif name == 'one-horizon':
            item['lens']['horizon'] = 1
        elif name == 'clock-mismatch':
            item['source']['clock'] = 'other-clock'
        elif name == 'generation-mismatch':
            item['source']['generation'] = 2
        elif name == 'window-end':
            item['lens']['end'] = 3
        elif name == 'unknown-time':
            item['source']['events'][1][1] = 'unknown'
        cases.append({'id': name, 'request': item})
    return cases
