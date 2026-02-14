export interface Plan {
  id: number;
  name: string;
}

export interface StaffGroup {
  id: number;
  plan_id: number;
  name: string;
  sort_order: number;
}

export interface StaffMember {
  id: number;
  group_id: number;
  name: string;
  sort_order: number;
}

export interface StaffGroupWithMembers {
  group: StaffGroup;
  members: StaffMember[];
}

export interface WeeklyRule {
  id: number;
  plan_id: number;
  name: string;
  sort_order: number;
}

export interface RuleAssignment {
  id: number;
  weekly_rule_id: number;
  weekday: number | string;
  shift_time_type: number | string;
  target_group_id: number;
  target_member_index: number;
}

export interface WeeklyRuleWithAssignments {
  rule: WeeklyRule;
  assignments: RuleAssignment[];
}

export interface PlanConfig {
  plan: Plan;
  groups: StaffGroupWithMembers[];
  rules: WeeklyRuleWithAssignments[];
}

export type WeekState = 'pending_active' | 'pending_skip' | 'fixed_active' | 'fixed_skip';

// カレンダー状態 (Rust Enum -> TS Tagged Union)


export interface ShiftCalendarManager {
  id?: number;
  planId: number;
  baseAbsWeek: number;
  initialDelta: number;
}

// 決定したシフトの型
export interface DailyShiftDto {
  morning: string[];
  afternoon: string[];
}

export interface WeeklyShiftDto {
  days: DailyShiftDto[];
}

export interface WeeklyShiftInfo {
  status: 'Pending' | 'Active' | 'Skipped';
  shift?: WeeklyShiftDto;
}

export interface MonthlyShiftResult {
  weeks: WeeklyShiftInfo[];
}
