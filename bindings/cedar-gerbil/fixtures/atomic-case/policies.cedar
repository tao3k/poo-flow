// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

permit(principal == User::"alice", action == Action::"run", resource == Job::"demo")
when { context.approved };

forbid(principal, action, resource)
when { context.blocked };
