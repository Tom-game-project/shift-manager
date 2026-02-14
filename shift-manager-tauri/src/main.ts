import "./styles.css";
import { PlanConfig } from "./types";
import { api } from "./api";
import { openInputModal, closeModal } from "./ui/modal";
import { renderConfigUI } from "./ui/config";
import { renderCalendarView } from "./ui/calendar";

/* ==========================================================================
   STATE
   ========================================================================== */
let currentPlanId: number | null = null;
let currentConfig: PlanConfig | null = null;
let currentYear = new Date().getFullYear();
let currentMonth = new Date().getMonth();

// 編集中のスキップ状態を保持するマップ
// Key: "YYYY-MM-DD" (週の月曜日の日付文字列)
// Value: true = Skip, false = Active
let pendingSkips: Record<string, boolean> = {};

/* ==========================================================================
   INIT
   ========================================================================== */
window.addEventListener('DOMContentLoaded', async () => {
    setupEventListeners();
    await loadPlanList();
});

async function loadPlanList() {
    try {
        const plans = await api.listPlans();
        const select = document.getElementById('plan-select') as HTMLSelectElement;
        if (!select) return;

        select.innerHTML = '<option value="" disabled selected>Select Plan...</option>';
        plans.forEach(plan => {
            const opt = document.createElement('option');
            opt.value = plan.id.toString();
            opt.textContent = plan.name;
            select.appendChild(opt);
        });
    } catch (e) {
        console.error("Failed to list plans", e);
    }
}

async function handlePlanChange(planId: number) {
    currentPlanId = planId;
    console.log("Plan Changed:", planId);
    await reloadConfig();
    await renderCalendarViewWrapped();
}

async function createNewPlan() {
    openInputModal("Create New Plan", "", async (name) => {
        if (!name) return;
        try {
            const newId = await api.createPlan(name);
            await loadPlanList();
            const select = document.getElementById('plan-select') as HTMLSelectElement;
            if (select) {
                select.value = newId.toString();
            }
            handlePlanChange(newId);
        } catch (e) {
            alert("Failed to create plan: " + e);
        }
    });
}

/* ==========================================================================
   CONFIG VIEW
   ========================================================================== */
async function reloadConfig() {
    if (!currentPlanId) return;
    try {
        console.log("Reloading config for plan:", currentPlanId);
        currentConfig = await api.getPlanConfig(currentPlanId);
        console.log("Config loaded:", currentConfig);
        renderConfigUI(currentConfig, reloadConfig);
    } catch (e) {
        console.error("Failed to load config", e);
    }
}

/* ==========================================================================
   CALENDAR VIEW Wrapper
   ========================================================================== */
async function renderCalendarViewWrapped() {
    if (!currentPlanId) return;
    await renderCalendarView(currentPlanId, currentYear, currentMonth, pendingSkips);
}

// Generateボタン: UI上のスキップ設定を集めてバックエンドへ送る
async function handleGenerate() {
    if (!currentPlanId) {
        alert("Please select a plan first.");
        return;
    }

    const mount = document.getElementById('calendar-mount');
    if (!mount) return;

    const checkboxes = mount.querySelectorAll('input[type="checkbox"]');
    const skipFlags: boolean[] = [];

    checkboxes.forEach((cb) => {
        const input = cb as HTMLInputElement;
        if (!input.disabled) {
            skipFlags.push(input.checked);
        }
    });

    if (skipFlags.length === 0) {
        alert("No new (pending) weeks to generate.");
        return;
    }

    console.log("Sending skips to Rust:", skipFlags);

    try {
        await api.generateAndSaveShift(currentPlanId, skipFlags, currentYear, currentMonth);
        pendingSkips = {}; // Clear pending state
        await renderCalendarViewWrapped();
        alert("Schedule Generated & Saved!");
    } catch (e) {
        console.error(e);
        alert(`Generate failed: ${e}`);
    }
}

/* ==========================================================================
   EVENT LISTENERS
   ========================================================================== */
function setupEventListeners() {
    // 1. Plan Select
    const planSelect = document.getElementById('plan-select');
    if (planSelect) {
        planSelect.addEventListener('change', (e) => {
            const val = (e.target as HTMLSelectElement).value;
            if (val) handlePlanChange(parseInt(val));
        });
    }

    // 2. Create Plan
    const createPlanBtn = document.getElementById('create-plan-btn');
    if (createPlanBtn) {
        createPlanBtn.addEventListener('click', createNewPlan);
    }

    // 3. View Switching
    const viewCalendar = document.getElementById('view-calendar');
    const viewConfig = document.getElementById('view-config');
    const btnViewer = document.getElementById('switch-viewer');
    const btnConfig = document.getElementById('switch-config');

    btnViewer?.addEventListener('click', () => {
        viewCalendar?.classList.add('active-view');
        viewConfig?.classList.remove('active-view');
        btnViewer.classList.add('active');
        btnConfig?.classList.remove('active');
        if (viewCalendar) viewCalendar.style.display = '';
        if (viewConfig) viewConfig.style.display = '';

        // Refresh calendar
        renderCalendarViewWrapped();
    });

    btnConfig?.addEventListener('click', () => {
        viewCalendar?.classList.remove('active-view');
        viewConfig?.classList.add('active-view');
        btnViewer?.classList.remove('active');
        btnConfig.classList.add('active');
        if (viewCalendar) viewCalendar.style.display = '';
        if (viewConfig) viewConfig.style.display = '';

        reloadConfig();
    });

    // Add Group
    const addGroupBtn = document.getElementById('add-group-btn');
    if (addGroupBtn) {
        addGroupBtn.addEventListener('click', async () => {
            if (!currentPlanId) return;
            await api.addStaffGroup(currentPlanId, "New Group");
            reloadConfig();
        });
    }

    // Add Rule
    const addRuleBtn = document.getElementById('add-rule-btn');
    if (addRuleBtn) {
        addRuleBtn.addEventListener('click', async () => {
            if (!currentPlanId) return;
            openInputModal("Create New Rule", "New Rule", async (name) => {
                if (!name) return;
                try {
                    await api.addWeeklyRule(currentPlanId!, name);
                    setTimeout(async () => {
                        await reloadConfig();
                    }, 100);
                } catch (e) {
                    alert(`Failed to add rule: ${e}`);
                }
            });
        });
    }

    // Calendar Actions
    document.getElementById('prev-btn')?.addEventListener('click', () => {
        currentMonth--;
        if (currentMonth < 0) { currentMonth = 11; currentYear--; }
        renderCalendarViewWrapped();
    });

    document.getElementById('next-btn')?.addEventListener('click', () => {
        currentMonth++;
        if (currentMonth > 11) { currentMonth = 0; currentYear++; }
        renderCalendarViewWrapped();
    });

    document.getElementById('generate-btn')?.addEventListener('click', handleGenerate);

    document.getElementById('reset-btn')?.addEventListener('click', async () => {
        if (!currentPlanId) {
            alert("No plan selected");
            return;
        }

        const monthLabel = document.getElementById('current-month-label')?.textContent;

        if (confirm(`Are you sure you want to delete ALL shifts starting from ${monthLabel}? This cannot be undone.`)) {
            try {
                await api.deleteFutureShifts(currentPlanId, currentYear, currentMonth);
                await renderCalendarViewWrapped();
                alert("Future shifts deleted.");
            } catch (e) {
                alert(`Failed to delete shifts: ${e}`);
            }
        }
    });


    // Modal
    document.getElementById('modal-cancel-btn')?.addEventListener('click', closeModal);
    document.getElementById('modal')?.addEventListener('click', (e) => {
        if ((e.target as HTMLElement).id === 'modal') closeModal();
    });
}
