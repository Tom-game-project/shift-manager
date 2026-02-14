import { api } from "../api";
import { calculateCalendarDates } from "../utils";
import { WeekState, MonthlyShiftResult } from "../types";

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





    mount.innerHTML = '';

    weeksData.forEach((week, i) => {
        const weekKey = week.days[0].toISOString().split('T')[0];

        // Default state from pending map
        let state: WeekState = pendingSkips[weekKey] ? 'pending_skip' : 'pending_active';

        // Override state if data is fixed in DB
        const weekInfo = shiftData?.weeks?.[i];
        if (weekInfo) {
            if (weekInfo.status === 'Active') {
                state = 'fixed_active';
            } else if (weekInfo.status === 'Skipped') {
                state = 'fixed_skip';
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
        input.disabled = state.startsWith('fixed_'); // Disable if fixed

        switch (state) {
            case 'pending_active':
            case 'fixed_active':
                input.checked = false;
                break;
            case 'pending_skip':
            case 'fixed_skip':
                input.checked = true;
                break;
        }

        input.onchange = (e) => {
            if (state.startsWith('fixed_')) return; // Should be disabled, but extra safety
            const isChecked = (e.target as HTMLInputElement).checked;
            pendingSkips[weekKey] = isChecked;

            const textEl = controlCell.querySelector('.status-text') as HTMLElement;
            if (textEl) {
                // Determine text based on checkbox state for pending items
                const newStateStr = isChecked ? "SKIP" : "ACTIVE";
                textEl.textContent = newStateStr;
                textEl.className = `status-text ${isChecked ? 'text-skip' : 'text-active'}`;
            }

            // Also update slider class
            const sliderEl = switchLabel.querySelector('.slider');
            if (sliderEl) {
                sliderEl.className = `slider ${isChecked ? 'pending-skip' : 'pending-active'}`;
            }
        };

        const slider = document.createElement('span');
        let sliderClass = '';
        if (state === 'pending_active') sliderClass = 'pending-active';
        else if (state === 'pending_skip') sliderClass = 'pending-skip';
        else if (state === 'fixed_active') sliderClass = 'fixed-active';
        else if (state === 'fixed_skip') sliderClass = 'fixed-skip';

        slider.className = `slider ${sliderClass}`;

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
                labelText = "ACTIVE (FIXED)";
                labelColorClass = "text-fixed-active";
                break;
            case 'fixed_skip':
                labelText = "SKIPPED (FIXED)";
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

            const weekInfo = shiftData?.weeks?.[i];
            if (weekInfo && weekInfo.shift) {
                const dailyShift = weekInfo.shift.days[dayIndex];
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





            row.appendChild(cell);
        });

        mount.appendChild(row);
    });
}
