use crate::domain::shift_calendar_model::{
    AbsWeek, 
    ShiftCalendarManager, 
    WeekStatus,
    RuleId,
};

use shift_calendar::shift_gen::{
    gen_one_week_shift,
    WeekRuleTable,
    WeekDecidedShift,
    StaffGroupList,
    Incomplete
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

impl ShiftCalendarManager {

    fn abs_to_index(
        &self, 
        abs_week: AbsWeek
    ) -> Result<usize, AppendWeekErrorKind> {
        // self.delta_to_index(self.abs_to_delta(abs_week)?)
        if abs_week < self.base_abs_week {
            Err(AppendWeekErrorKind::UnderFlow)
        } else {
            Ok(abs_week - self.base_abs_week)
        }
    }
}

use std::collections::HashMap;

/// 指定された期間のシフトのみを計算する純粋関数
///
/// - `timeline_slice`: 計算対象の週のステータス（例: 4週間分だけ）
/// - `rule_map`: rule_id から 実際のWeekRule へのマップ (必要な分だけ)
/// - `staff_groups`: スタッフリスト (これはサイズが小さいので全件でもOKだが、最適化も可能)
pub fn calculate_partial_shift<'a>(
    timeline_slice: &[WeekStatus],
    rule_map: &HashMap<RuleId, WeekRuleTable<'a, Incomplete>>, // ID -> Rule
    staff_group_list: &'a StaffGroupList,
) -> Vec<Option<WeekDecidedShift<'a>>> {
    timeline_slice
        .iter().map(|i|{
            if let WeekStatus::Active { logical_delta , rule_id} = i {
                rule_map
                    .get(rule_id)
                    .map(|week_rule_table| 
                        gen_one_week_shift(
                            week_rule_table, 
                            staff_group_list,
                            *logical_delta
                        )
                    )
            } else {
                None
            }
        }).collect()
}

