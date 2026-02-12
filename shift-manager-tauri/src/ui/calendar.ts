
import { calculateCalendarDates } from "../utils";
import { WeekState } from "../types";

export async function renderCalendarView(
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





    mount.innerHTML = '';

    weeksData.forEach((week) => {
        const weekKey = week.days[0].toISOString().split('T')[0];
        let state: WeekState = 'pending_active';

        if (pendingSkips[weekKey] === true) {
            state = 'pending_skip';
        } else {
            state = 'pending_active';
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
        const sliderClass = state === 'pending_active' ? 'pending-active' : 'pending-skip'; // simplified since fix is gone
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

        }

        statusText.classList.add(labelColorClass);
        statusText.textContent = labelText;
        statusText.style.fontSize = "0.7em";
        statusText.style.fontWeight = "bold";
        statusText.style.marginTop = "4px";

        controlCell.appendChild(statusText);
        row.appendChild(controlCell);

        // Day Cells
        week.days.forEach((day) => {
            const cell = document.createElement('div');
            cell.className = 'cal-cell-day';
            cell.textContent = day.getDate().toString();

            if (day.getMonth() !== month) {
                cell.style.opacity = '0.3';
            }





            row.appendChild(cell);
        });

        mount.appendChild(row);
    });
}
