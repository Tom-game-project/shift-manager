import { StaffGroupWithMembers } from "../types";
import { getGroupColor, getGroupPrefix } from "../utils";

export function closeModal() {
    const modal = document.getElementById('modal');
    if (modal) modal.style.display = 'none';
}

export function openInputModal(
    title: string,
    defaultValue: string,
    onConfirm: (value: string) => void,
    placeholder: string = "Enter value..."
) {
    const modal = document.getElementById('modal');
    const modalBody = document.getElementById('modal-body');
    const modalTitle = document.getElementById('modal-title');
    const cancelBtn = document.getElementById('modal-cancel-btn');

    if (!modal || !modalBody || !modalTitle) return;

    modalTitle.textContent = title;
    modalBody.innerHTML = ''; // Clear previous content

    // Input Container
    const container = document.createElement('div');
    container.style.display = 'flex';
    container.style.flexDirection = 'column';
    container.style.gap = '15px';

    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'form-select'; // Reuse style
    input.style.width = '100%';
    input.style.padding = '10px';
    input.value = defaultValue;
    input.placeholder = placeholder;

    // Auto focus
    setTimeout(() => input.focus(), 100);

    const confirmBtn = document.createElement('button');
    confirmBtn.className = 'btn btn-primary';
    confirmBtn.textContent = 'Save';
    confirmBtn.style.alignSelf = 'flex-end';

    confirmBtn.onclick = () => {
        onConfirm(input.value);
        closeModal();
    };

    // Allow Enter key
    input.onkeydown = (e) => {
        if (e.key === 'Enter') {
            onConfirm(input.value);
            closeModal();
        }
    };

    container.appendChild(input);
    container.appendChild(confirmBtn);

    modalBody.appendChild(container);
    modal.style.display = 'flex';

    if (cancelBtn) {
        cancelBtn.onclick = () => closeModal();
    }
}

export function openAssignmentModal(
    ruleId: number,
    weekday: number,
    shiftTime: number,
    groups: StaffGroupWithMembers[],
    onAssign: (ruleId: number, weekday: number, shiftTime: number, groupId: number, memberIndex: number) => void
) {
    const modal = document.getElementById('modal');
    const modalBody = document.getElementById('modal-body');
    const modalTitle = document.getElementById('modal-title');

    if (!modal || !modalBody || !modalTitle) return;

    // タイトル設定
    const dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday];
    const timeName = shiftTime === 0 ? "Morning" : "Afternoon";
    modalTitle.textContent = `Assign to ${dayName} - ${timeName}`

    // コンテンツ生成
    modalBody.innerHTML = '';

    if (groups.length === 0) {
        modalBody.innerHTML = '<p>No staff groups defined yet.</p>';
    }

    groups.forEach((g, index) => {
        const color = getGroupColor(index);
        const prefix = getGroupPrefix(index);

        const groupDiv = document.createElement('div');
        groupDiv.style.marginBottom = '15px';

        const header = document.createElement('div');
        header.style.fontWeight = 'bold';
        header.style.color = color;
        header.style.borderBottom = `2px solid ${color}`;
        header.style.marginBottom = '5px';
        header.innerHTML = `<span style="font-weight:900; margin-right:5px;">${prefix}</span> ${g.group.name}`;

        groupDiv.appendChild(header);

        const grid = document.createElement('div');
        grid.style.display = 'grid';
        grid.style.gridTemplateColumns = 'repeat(auto-fill, minmax(100px, 1fr))';
        grid.style.gap = '8px';

        g.members.forEach((_, mIndex) => {
            const btn = document.createElement('button');
            btn.className = 'btn btn-outline-light';
            btn.style.color = '#333';
            btn.style.border = '1px solid #ddd';
            btn.style.borderLeft = `4px solid ${color}`;
            btn.style.padding = '8px';
            btn.style.textAlign = 'center';
            btn.style.cursor = 'pointer';
            btn.textContent = `#${mIndex}`;

            btn.onclick = () => {
                onAssign(ruleId, weekday, shiftTime, g.group.id, mIndex);
                closeModal();
            };

            grid.appendChild(btn);
        });

        groupDiv.appendChild(grid);
        modalBody.appendChild(groupDiv);
    });

    modal.style.display = 'flex';
}
