import { PlanConfig, StaffGroupWithMembers } from "../types";
import { getGroupColor, getGroupPrefix, normalizeWeekday, normalizeShiftTime } from "../utils";
import { api } from "../api";
import { openInputModal, openAssignmentModal } from "./modal";

export function renderConfigUI(
    config: PlanConfig,
    onReload: () => Promise<void>
) {
    renderGroups(config.groups, onReload);
    renderGroups(config.groups, onReload);
    renderRules(config, onReload); // pass full config for group lookups
    renderCalendarSettings(config.plan.id);

    const jsonEl = document.getElementById('json-output');
    if (jsonEl) jsonEl.textContent = JSON.stringify(config, null, 2);
}

function renderGroups(groups: StaffGroupWithMembers[], onReload: () => Promise<void>) {
    const container = document.getElementById('staff-groups-container');
    if (!container) return;
    container.innerHTML = '';

    groups.forEach((g, index) => {
        const color = getGroupColor(index);
        const prefix = getGroupPrefix(index);

        const div = document.createElement('div');
        div.className = 'group-card';
        div.style.marginBottom = '15px';
        div.style.borderLeft = `5px solid ${color}`;
        div.style.borderLeft = `5px solid ${color}`;

        // Header
        const header = document.createElement('div');
        header.style.padding = '10px';
        header.style.background = '#f8fafc';
        header.style.borderBottom = '1px solid #e2e8f0';
        header.style.display = 'flex';
        header.style.justifyContent = 'space-between';
        header.style.alignItems = 'center';

        header.innerHTML = `
            <div style="display:flex; align-items:center; gap:8px;">
                <span style="background:${color}; color:white; font-weight:bold; padding:2px 8px; border-radius:4px; font-size:0.9em;">
                    ${prefix}
                </span>
                <strong>${g.group.name}</strong>
            </div>
        `;

        const btnGroup = document.createElement('div');

        const renameBtn = document.createElement('button');
        renameBtn.className = 'btn-sm btn-outline';
        renameBtn.textContent = 'Rename';
        renameBtn.onclick = () => {
            openInputModal("Rename Group", "", async (name) => {
                if (name) { await api.updateGroupName(g.group.id, name); onReload(); }
            });
        };

        const delBtn = document.createElement('button');
        delBtn.className = 'btn-sm btn-danger';
        delBtn.textContent = 'Del';
        delBtn.style.marginLeft = '5px';
        delBtn.onclick = async () => {
            if (confirm("Delete group?")) {
                await api.deleteStaffGroup(g.group.id);
                onReload();
            }
        };

        btnGroup.appendChild(renameBtn);
        btnGroup.appendChild(delBtn);
        header.appendChild(btnGroup);
        div.appendChild(header);

        // List
        const list = document.createElement('div');
        list.className = 'members-list';
        list.style.padding = '10px';

        if (g.members.length === 0) {
            list.innerHTML = '<div style="color:#aaa; font-size:0.9em; font-style:italic;">No members yet.</div>';
        } else {
            g.members.forEach(m => {
                const mDiv = document.createElement('div');
                mDiv.style.display = 'flex';
                mDiv.style.justifyContent = 'space-between';
                mDiv.style.alignItems = 'center';
                mDiv.style.padding = '5px 0';
                mDiv.style.borderBottom = '1px solid #f0f0f0';

                mDiv.innerHTML = `
                    <div style="display:flex; align-items:center; gap:5px;">
                        <span style="color:#888; font-size:0.8em; width:20px;">#${m.sort_order}</span>
                        <span>${m.name}</span>
                    </div>
                `;

                const mActions = document.createElement('div');

                const editBtn = document.createElement('button');
                editBtn.className = 'btn-sm btn-outline';
                editBtn.style.fontSize = '0.7em';
                editBtn.style.marginRight = '5px';
                editBtn.textContent = 'Edit';
                editBtn.onclick = () => {
                    openInputModal("Rename Member", "", async (newName) => {
                        if (newName && newName.trim() !== "") {
                            try {
                                await api.updateMemberName(m.id, newName.trim());
                                onReload();
                            } catch (e) {
                                alert(`Failed to update member name: ${e}`);
                            }
                        }
                    });
                };

                const removeBtn = document.createElement('button');
                removeBtn.className = 'btn-sm btn-outline-danger';
                removeBtn.style.fontSize = '0.7em';
                removeBtn.textContent = 'x';
                removeBtn.onclick = async () => {
                    await api.deleteStaffMember(m.id);
                    onReload();
                };

                mActions.appendChild(editBtn);
                mActions.appendChild(removeBtn);
                mDiv.appendChild(mActions);
                list.appendChild(mDiv);
            });
        }
        div.appendChild(list);

        // Footer
        const footer = document.createElement('div');
        footer.style.padding = '0 10px 10px 10px';

        const addBtn = document.createElement('button');
        addBtn.className = "btn-sm btn-outline";
        addBtn.style.width = "100%";
        addBtn.style.borderStyle = "dashed";
        addBtn.textContent = "+ Add Member";
        addBtn.onclick = async () => {
            await api.addStaffMember(g.group.id, "New Member");
            onReload();
        };

        footer.appendChild(addBtn);
        div.appendChild(footer);
        container.appendChild(div);
    });
}

function renderRules(config: PlanConfig, onReload: () => Promise<void>) {
    const rules = config.rules;
    const container = document.getElementById('rules-container');
    if (!container) return;
    container.innerHTML = '';

    rules.forEach((r, rIdx) => {
        const div = document.createElement('div');
        div.className = 'rule-card';
        // Inline styles removed, handled by CSS class

        // Rule Header
        const header = document.createElement('div');
        header.style.display = 'flex';
        header.style.justifyContent = 'space-between';
        header.style.alignItems = 'center';
        header.style.borderBottom = '1px solid #eee';
        header.style.paddingBottom = '10px';
        header.style.marginBottom = '10px';

        header.innerHTML = `
            <div style="display:flex; align-items:center; gap:10px;">
                <strong style="font-size:1.1em;">Week ${rIdx + 1}</strong>
            </div>
        `;

        const btnGroup = document.createElement('div');
        // Rename (Not fully implemented in main.ts, but standard pattern)
        // main.ts had window.updateRuleName but no implementation. I will omit for now or add a dummy.
        // Assuming delete is key.

        const delBtn = document.createElement('button');
        delBtn.className = 'btn-sm btn-danger';
        delBtn.textContent = 'Del';
        delBtn.onclick = async () => {
            if (confirm("Delete rule?")) {
                await api.deleteWeeklyRule(r.rule.id);
                onReload();
            }
        };
        btnGroup.appendChild(delBtn);
        header.appendChild(btnGroup);
        div.appendChild(header);

        // Grid
        const gridDiv = document.createElement('div');
        gridDiv.className = 'assignments-grid';
        gridDiv.style.overflowX = 'auto';

        const table = document.createElement('table');
        table.style.width = '100%';
        table.style.borderCollapse = 'collapse';
        table.style.fontSize = '0.9em';

        const thead = document.createElement('thead');
        thead.innerHTML = `
            <tr style="background:#f9f9f9; text-align:left; border-bottom:2px solid #eee;">
                <th style="padding:8px;">Time</th>
                ${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(d => `<th style="padding:8px; min-width:80px;">${d}</th>`).join('')}
            </tr>
        `;
        table.appendChild(thead);

        const tbody = document.createElement('tbody');

        [0, 1].forEach(shiftTime => {
            const tr = document.createElement('tr');
            tr.style.borderTop = '1px solid #eee';

            const timeLabel = document.createElement('td');
            timeLabel.textContent = shiftTime === 0 ? "AM" : "PM";
            timeLabel.style.fontWeight = "bold";
            timeLabel.style.padding = "8px";
            timeLabel.style.color = shiftTime === 0 ? "#dc2626" : "#2563eb"; // Red : Blue
            tr.appendChild(timeLabel);

            for (let weekday = 0; weekday < 7; weekday++) {
                const td = document.createElement('td');
                td.style.padding = "5px";
                td.style.verticalAlign = "top";
                td.style.borderLeft = "1px solid #f5f5f5";

                const assigns = r.assignments.filter(a =>
                    normalizeWeekday(a.weekday) === weekday &&
                    normalizeShiftTime(a.shift_time_type) === shiftTime
                );

                assigns.forEach(a => {
                    const groupIndex = config.groups.findIndex(g => g.group.id === a.target_group_id);
                    const groupData = groupIndex >= 0 ? config.groups[groupIndex] : null;

                    const color = groupIndex >= 0 ? getGroupColor(groupIndex) : '#999';
                    const prefix = groupIndex >= 0 ? getGroupPrefix(groupIndex) : '?';
                    const memberName = groupData?.members[a.target_member_index]?.name || "Unknown";

                    const chip = document.createElement('div');
                    chip.style.border = `1px solid ${color}`;
                    chip.style.borderLeft = `5px solid ${color}`;
                    chip.style.background = '#fcfcfc';
                    chip.style.color = '#333';
                    chip.style.padding = '2px 6px';
                    chip.style.borderRadius = '3px';
                    chip.style.marginBottom = '4px';
                    chip.style.fontSize = '0.9em';
                    chip.style.fontWeight = 'bold';
                    chip.style.cursor = 'pointer';
                    chip.style.whiteSpace = 'nowrap';
                    chip.style.boxShadow = '0 1px 2px rgba(0,0,0,0.1)';
                    chip.style.display = 'inline-block';
                    chip.style.marginRight = '4px';
                    chip.textContent = `${prefix}-${a.target_member_index}`;
                    chip.title = `${groupData?.group.name || 'Unknown'}: ${memberName}`;

                    chip.onclick = async (e) => {
                        e.stopPropagation();
                        if (confirm(`Remove assignment ${prefix}-${a.target_member_index} (${memberName})?`)) {
                            try {
                                await api.deleteAssignment(a.id);
                                onReload();
                            } catch (e) {
                                console.error(e);
                                alert("Failed to remove assignment");
                            }
                        }
                    };
                    td.appendChild(chip);
                });

                // Shift Holes (Visual Placeholder)
                // This is where "Shift Hole" logic goes.
                // If there are assignments, we show them.
                // If we want to show "Empty/Hole", we can check if enough people are assigned?
                // But we don't know the required number.
                // The user said "Display shift holes (hole where someone is PLANNED to enter)".
                // I'll make the "Add" button look more like a "Hole" to fill.

                const holeBtn = document.createElement('button');
                holeBtn.className = "shift-hole-btn";
                holeBtn.innerHTML = "<span style='font-size:1.2em; line-height:1;'>+</span>";
                holeBtn.title = "Click to assign staff (fill hole)";

                // Hover effects handled by CSS

                holeBtn.onclick = () => {
                    openAssignmentModal(r.rule.id, weekday, shiftTime, config.groups, async (rid, wd, st, gid, mid) => {
                        await api.addAssignment(rid, wd, st, gid, mid);
                        onReload();
                    });
                };

                td.appendChild(holeBtn);
                tr.appendChild(td);
            }
            tbody.appendChild(tr);
        });

        table.appendChild(tbody);
        gridDiv.appendChild(table);
        div.appendChild(gridDiv);
        container.appendChild(div);
    });
}

async function renderCalendarSettings(planId: number) {
    const container = document.getElementById('calendar-settings-container');
    if (!container) return;
    container.innerHTML = 'Loading settings...';

    try {
        const calendarState = await api.getCalendarState(planId);
        container.innerHTML = '';

        if (!calendarState) {
            const presetKey = `initialDelta:${planId}`;
            const storedDelta = localStorage.getItem(presetKey);
            const presetDelta = storedDelta !== null ? storedDelta : "0";

            container.innerHTML = `
                <div style="color:#888; font-style:italic; margin-bottom:10px;">
                    No calendar initialized for this plan yet.
                </div>
                <div style="background:#fff; padding:15px; border-radius:8px; box-shadow:0 2px 5px rgba(0,0,0,0.05);">
                    <h4 style="margin-top:0; margin-bottom:10px;">Initial Logical Delta (Pre-Calendar)</h4>
                    <div style="display:flex; gap:10px; align-items:center;">
                        <input type="number" id="initial-delta-input" value="${presetDelta}" style="padding:5px; border:1px solid #ccc; border-radius:4px; width:100px;">
                        <button id="save-delta-btn" class="btn-sm btn-outline">Save</button>
                        <span id="save-msg" style="font-size:0.9em; color:green; display:none;">Saved!</span>
                    </div>
                    <p style="font-size:0.8em; color:#666; margin-top:5px;">
                        This value will be used the first time you generate a schedule and the calendar is created.
                    </p>
                </div>
            `;

            const btn = document.getElementById('save-delta-btn');
            const input = document.getElementById('initial-delta-input') as HTMLInputElement;
            const msg = document.getElementById('save-msg');

            if (btn && input) {
                btn.onclick = () => {
                    const val = parseInt(input.value);
                    if (isNaN(val) || val < 0) {
                        alert("Please enter a valid non-negative number.");
                        return;
                    }

                    localStorage.setItem(presetKey, val.toString());
                    if (msg) {
                        msg.style.display = 'inline';
                        setTimeout(() => { msg.style.display = 'none'; }, 2000);
                    }
                };
            }

            return;
        }

        const div = document.createElement('div');
        div.style.background = '#fff';
        div.style.padding = '15px';
        div.style.borderRadius = '8px';
        div.style.boxShadow = '0 2px 5px rgba(0,0,0,0.05)';
        div.style.marginBottom = '20px';

        div.innerHTML = `
            <h4 style="margin-top:0; margin-bottom:10px;">Calendar Settings</h4>
            <div style="margin-bottom: 10px;">
                <label style="display:block; font-weight:bold; margin-bottom:5px;">Initial Logical Delta</label>
                <div style="display:flex; gap:10px; align-items:center;">
                    <input type="number" id="initial-delta-input" value="${calendarState.initialDelta}" style="padding:5px; border:1px solid #ccc; border-radius:4px; width:100px;">
                    <button id="save-delta-btn" class="btn-sm btn-outline">Update</button>
                    <span id="save-msg" style="font-size:0.9em; color:green; display:none;">Saved!</span>
                </div>
                <p style="font-size:0.8em; color:#666; margin-top:5px;">
                    Adjust the starting rotation of the shift sequence. 
                    Changing this will affect the entire shift pattern generation.
                </p>
            </div>
            <div style="font-size:0.8em; color:#999;">
                Base Week: ${calendarState.baseAbsWeek}
            </div>
        `;

        container.appendChild(div);

        const btn = document.getElementById('save-delta-btn');
        const input = document.getElementById('initial-delta-input') as HTMLInputElement;
        const msg = document.getElementById('save-msg');

        if (btn && input) {
            btn.onclick = async () => {
                const val = parseInt(input.value);
                if (isNaN(val) || val < 0) {
                    alert("Please enter a valid non-negative number.");
                    return;
                }

                try {
                    btn.textContent = "Saving...";
                    (btn as HTMLButtonElement).disabled = true;
                    await api.updateInitialDelta(planId, val);

                    if (msg) {
                        msg.style.display = 'inline';
                        setTimeout(() => { msg.style.display = 'none'; }, 2000);
                    }
                } catch (e) {
                    alert(`Failed to update settings: ${e}`);
                } finally {
                    btn.textContent = "Update";
                    (btn as HTMLButtonElement).disabled = false;
                }
            };
        }

    } catch (e) {
        container.innerHTML = `<div style="color:red;">Failed to load calendar settings: ${e}</div>`;
    }
}
