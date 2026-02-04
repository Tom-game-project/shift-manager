import { api } from "../api";
import { calculateCalendarDates } from "../utils";
import { WeekStatus, WeekState, MonthlyShiftResult } from "../types";

export async function renderCalendarView(
    planId: number,
    year: number,
    month: number,
    pendingSkips: Record<string, boolean>
) {
    const label = document.getElementById('current-month-label');
    if (label) {
        const date = new Date(year, month, 1);
        label.textContent = date.toLocaleDateString('ja-JP', { year: 'numeric', month: 'long' });
    }

    const mount = document.getElementById('calendar-mount');
    if (!mount) return;
    mount.innerHTML = '<div style="padding:20px; text-align:center;">Loading...</div>';

    const weeksData = calculateCalendarDates(year, month);

    let shiftData: MonthlyShiftResult = { weeks: [] };
    try {
        shiftData = await api.deriveMonthlyShift(planId, year, month);
    } catch (e) {
        console.error("Failed to derive shifts:", e);
    }

    let savedTimeline: WeekStatus[] = [];
    try {
        const savedManager = await api.getCalendarState(planId);
        if (savedManager) {
            savedTimeline = savedManager.timeline;
        }
    } catch (e) {
        // No saved state
    }

    mount.innerHTML = '';

    weeksData.forEach((week, i) => {
        const weekKey = week.days[0].toISOString().split('T')[0];
        let state: WeekState = 'pending_active';

        const savedStatus = savedTimeline[i]; // Approximate index matching

        if (savedStatus) {
            if (savedStatus.type === 'skipped') {
                state = 'fixed_skip';
            } else {
                state = 'fixed_active';
            }
        } else {
            if (pendingSkips[weekKey] === true) {
                state = 'pending_skip';
            } else {
                state = 'pending_active';
            }
        }

        const row = document.createElement('div');
        row.className = 'cal-week-row';

        // Control Cell
        const controlCell = document.createElement('div');
        controlCell.className = 'cal-cell-control';

        const switchLabel = document.createElement('label');
        switchLabel.className = 'switch';

        const input = document.createElement('input');
        input.type = 'checkbox';

        switch (state) {
            case 'pending_active':
                input.checked = false;
                input.disabled = false;
                break;
            case 'pending_skip':
                input.checked = true;
                input.disabled = false;
                break;
            case 'fixed_active':
                input.checked = false;
                input.disabled = true;
                break;
            case 'fixed_skip':
                input.checked = true;
                input.disabled = true;
                break;
        }

        input.onchange = (e) => {
            const isChecked = (e.target as HTMLInputElement).checked;
            pendingSkips[weekKey] = isChecked;

            const textEl = controlCell.querySelector('.status-text') as HTMLElement;
            if (textEl) {
                textEl.textContent = isChecked ? "SKIP" : "ACTIVE";
                textEl.className = `status-text ${isChecked ? 'text-skip' : 'text-active'}`;
            }
        };

        const slider = document.createElement('span');
        slider.className = `slider ${state.replace('_', '-')}`;

        switchLabel.appendChild(input);
        switchLabel.appendChild(slider);
        controlCell.appendChild(switchLabel);

        const statusText = document.createElement('span');
        statusText.classList.add('status-text');

        let labelText = "";
        let labelColorClass = "";

        switch (state) {
            case 'pending_active':
                labelText = "ACTIVE";
                labelColorClass = "text-active";
                break;
            case 'pending_skip':
                labelText = "SKIP";
                labelColorClass = "text-skip";
                break;
            case 'fixed_active':
                labelText = "FIXED";
                labelColorClass = "text-fixed-active";
                break;
            case 'fixed_skip':
                labelText = "VOID";
                labelColorClass = "text-fixed-skip";
                break;
        }

        statusText.classList.add(labelColorClass);
        statusText.textContent = labelText;
        statusText.style.fontSize = "0.7em";
        statusText.style.fontWeight = "bold";
        statusText.style.marginTop = "4px";

        controlCell.appendChild(statusText);
        row.appendChild(controlCell);

        // Day Cells
        week.days.forEach((day, dayIndex) => {
            const cell = document.createElement('div');
            cell.className = 'cal-cell-day';
            cell.textContent = day.getDate().toString();

            if (day.getMonth() !== month) {
                cell.style.opacity = '0.3';
            }

            if (state.startsWith('fixed')) {
                cell.style.backgroundColor = '#f9f9f9';
                cell.style.color = '#888';
            }

            if (state === 'fixed_active') {
                const weekShift = shiftData?.weeks?.[i];
                if (weekShift) {
                    const dailyShift = weekShift.days[dayIndex];
                    if (dailyShift) {
                        if (dailyShift.morning && dailyShift.morning.length > 0) {
                            const mBadge = document.createElement('div');
                            mBadge.className = 'shift-badge morning';
                            mBadge.style.fontSize = '0.75em';
                            mBadge.style.backgroundColor = 'var(--primary-soft)';
                            mBadge.style.color = 'var(--primary-dark)';
                            mBadge.style.padding = '2px 6px';
                            mBadge.style.borderRadius = '12px';
                            mBadge.style.marginBottom = '4px';
                            mBadge.style.fontWeight = '500';
                            mBadge.textContent = `AM: ${dailyShift.morning.join(', ')}`;
                            cell.appendChild(mBadge);
                        }
                        if (dailyShift.afternoon && dailyShift.afternoon.length > 0) {
                            const aBadge = document.createElement('div');
                            aBadge.className = 'shift-badge afternoon';
                            aBadge.style.fontSize = '0.75em';
                            aBadge.style.backgroundColor = 'hsl(340, 100%, 95%)';
                            aBadge.style.color = 'hsl(340, 60%, 50%)';
                            aBadge.style.padding = '2px 6px';
                            aBadge.style.borderRadius = '12px';
                            aBadge.style.fontWeight = '500';
                            aBadge.textContent = `PM: ${dailyShift.afternoon.join(', ')}`;
                            cell.appendChild(aBadge);
                        }
                    }
                }
            }

            row.appendChild(cell);
        });

        mount.appendChild(row);
    });
}
