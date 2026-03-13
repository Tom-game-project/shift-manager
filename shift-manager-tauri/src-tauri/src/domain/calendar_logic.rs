use crate::domain::shift_calendar_model::{AbsWeek, RuleId, ShiftCalendarManager, WeekStatus};

use shift_calendar::shift_gen::{
    gen_one_week_shift, Incomplete, StaffGroupList, WeekDecidedShift, WeekRuleTable,
};

// TODO このエラーを本当にここに置くべきか
#[derive(Debug)]
pub enum AppendWeekErrorKind {
    /// 予定の上書きエラー
    AttemptedToOverwrite,
    /// 連続しない予定エラー
    NotConsecutiveShifts,
    /// 加減突破
    UnderFlow,
}

/// 指定された期間のシフトのみを計算する純粋関数
///
/// - `timeline_slice`: 計算対象の週のステータス（例: 4週間分だけ）
/// - `rule_map`: rule_id から 実際のWeekRule へのマップ (必要な分だけ)
/// - `staff_groups`: スタッフリスト (これはサイズが小さいので全件でもOKだが、最適化も可能)
pub fn calculate_partial_shift<'a>(
    delta: usize,
    timeline_slice: &[WeekStatus],
    rule_map: &WeekRuleTable<'a, Incomplete>, // ID -> Rule
    staff_group_list: &'a StaffGroupList,
) -> Vec<Option<WeekDecidedShift<'a>>> {
    timeline_slice
        .iter()
        .map(|i| {
            if let WeekStatus::Active {
                logical_delta,
                rule_id,
            } = i
            {
                Some(gen_one_week_shift(
                    &rule_map,
                    staff_group_list,
                    *logical_delta + delta,
                ))
            } else {
                None
            }
        })
        .collect()
}
