
// グループごとの色パレット
export const GROUP_COLORS = [
    '#e67e22', // Orange (A)
    '#27ae60', // Green (B)
    '#2980b9', // Blue (C)
    '#8e44ad', // Purple (D)
    '#c0392b', // Red (E)
    '#16a085', // Teal (F)
    '#d35400', // Pumpkin (G)
    '#2c3e50', // Midnight (H)
];

export function getGroupColor(index: number): string {
    return GROUP_COLORS[index % GROUP_COLORS.length];
}

export function getGroupPrefix(index: number): string {
    // 0 -> A, 1 -> B ...
    return String.fromCharCode(65 + index);
}

export function calculateCalendarDates(year: number, month: number) {
    const weeks = [];
    const firstDay = new Date(year, month, 1);
    const dayOfWeek = (firstDay.getDay() + 6) % 7;
    const startDate = new Date(firstDay);
    startDate.setDate(firstDay.getDate() - dayOfWeek);

    const currentProcessDate = new Date(startDate);
    let weekCounter = 1;

    // ループガード: 最大6週間分だけ生成（万が一の場合の無限ループ防止）
    for (let w = 0; w < 6; w++) {
        const weekDays: Date[] = [];
        let hasCurrentMonthDay = false;
        for (let i = 0; i < 7; i++) {
            const d = new Date(currentProcessDate);
            weekDays.push(d);
            if (d.getMonth() === month) hasCurrentMonthDay = true;
            currentProcessDate.setDate(currentProcessDate.getDate() + 1);
        }

        // 週のすべてが翌月になったら終了
        if (!hasCurrentMonthDay && weeks.length > 0) break;

        weeks.push({ weekId: `${year}-W${weekCounter}`, days: weekDays });
        weekCounter++;
    }
    return weeks;
}

// Helpers for matching Rust enums (String or Number)
export function normalizeWeekday(val: string | number): number {
    if (typeof val === 'number') return val;
    switch (val) {
        case "Monday": return 0;
        case "Tuesday": return 1;
        case "Wednesday": return 2;
        case "Thursday": return 3;
        case "Friday": return 4;
        case "Saturday": return 5;
        case "Sunday": return 6;
        default: return -1;
    }
}

export function normalizeShiftTime(val: string | number): number {
    if (typeof val === 'number') return val;
    switch (val) {
        case "Morning": return 0;
        case "Afternoon": return 1;
        default: return -1;
    }
}
