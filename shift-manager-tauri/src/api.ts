import { invoke } from "@tauri-apps/api/core";
import { Plan, PlanConfig, MonthlyShiftResult, ShiftCalendarManager } from "./types";

export const api = {
    listPlans: () => invoke<Plan[]>("list_all_plans"),
    createPlan: (name: string) => invoke<number>("create_new_plan", { name }),
    getPlanConfig: (planId: number) => invoke<PlanConfig>("get_plan_config", { planId }),
    addStaffGroup: (planId: number, name: string) => invoke("add_staff_group", { planId, name }),
    deleteStaffGroup: (groupId: number) => invoke("delete_staff_group", { groupId }),
    updateGroupName: (groupId: number, name: string) => invoke("update_group_name", { groupId, name }),
    addStaffMember: (groupId: number, name: string) => invoke("add_staff_member", { groupId, name }),
    deleteStaffMember: (memberId: number) => invoke("delete_staff_member", { memberId }),
    updateMemberName: (memberId: number, name: string) => invoke("update_member_name", { memberId, name }),
    addWeeklyRule: (planId: number, name: string) => invoke("add_weekly_rule", { planId, name }),
    deleteWeeklyRule: (ruleId: number) => invoke("delete_weekly_rule", { ruleId }),
    // handle renaming rule if implemented in backend? main.ts had updateRuleName calls but seemingly check if it exists or not.
    // Wait, main.ts had `window.updateRuleName` but I don't see the implementation in the provided code snippet unless I missed it.
    // Looking at the snippet: 
    // line 225: onclick="window.updateRuleName(${r.rule.id})"
    // Yet `window.updateRuleName` was NOT assigned at the bottom.
    // It might be missing in main.ts or I missed it. I will assume I need to implement it or it was missing.
    // Actually, I did NOT see `updateRuleName` function definition in `main.ts` outline or content.
    // It might have been a bug in the code I read.
    // I will add the API call if I find it, otherwise note it.

    addAssignment: (ruleId: number, weekday: number, shiftTime: number, groupId: number, memberIndex: number) =>
        invoke("add_rule_assignment", { ruleId, weekday, shiftTime, groupId, memberIndex }),
    deleteAssignment: (assignmentId: number) => invoke("delete_assignment", { assignmentId }),

    generateAndSaveShift: (planId: number, skips: boolean[]) => invoke("generate_and_save_shift", { planId, skips }),
    deriveMonthlyShift: (planId: number, targetYear: number, targetMonth: number) =>
        invoke<MonthlyShiftResult>("derive_monthly_shift", { planId, targetYear, targetMonth }),
    getCalendarState: (planId: number) => invoke<ShiftCalendarManager>("get_calendar_state", { planId }),
};
