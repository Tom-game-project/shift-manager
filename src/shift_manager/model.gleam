import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element, text}
import lustre/element/html.{
  button, div, h1, h2, h3, input, main as html_main, nav, option, p, section,
  select,
}
import lustre/event.{on_change, on_check, on_click, on_input}

@external(javascript, "../ffi.js", "listPlans")
fn ffi_list_plans() -> promise.Promise(List(#(Int, String)))

@external(javascript, "../ffi.js", "currentDate")
fn ffi_current_date() -> #(Int, Int)

@external(javascript, "../ffi.js", "calendarGrid")
fn ffi_calendar_grid(
  year: Int,
  month: Int,
) -> List(#(String, List(#(Int, Bool))))

@external(javascript, "../ffi.js", "createPlan")
fn ffi_create_plan(name: String) -> promise.Promise(Int)

@external(javascript, "../ffi.js", "getPlanConfig")
fn ffi_get_plan_config(
  plan_id: Int,
) -> promise.Promise(
  #(
    #(Int, String),
    List(#(Int, String, List(#(Int, String, Int)))),
    List(#(Int, String, List(#(Int, Int, Int, Int, Int)))),
  ),
)

@external(javascript, "../ffi.js", "addStaffGroup")
fn ffi_add_staff_group(plan_id: Int, name: String) -> promise.Promise(Int)

@external(javascript, "../ffi.js", "deleteStaffGroup")
fn ffi_delete_staff_group(group_id: Int) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "updateGroupName")
fn ffi_update_group_name(group_id: Int, name: String) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "addStaffMember")
fn ffi_add_staff_member(group_id: Int, name: String) -> promise.Promise(Int)

@external(javascript, "../ffi.js", "deleteStaffMember")
fn ffi_delete_staff_member(member_id: Int) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "updateMemberName")
fn ffi_update_member_name(member_id: Int, name: String) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "addWeeklyRule")
fn ffi_add_weekly_rule(plan_id: Int, name: String) -> promise.Promise(Int)

@external(javascript, "../ffi.js", "deleteWeeklyRule")
fn ffi_delete_weekly_rule(rule_id: Int) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "updateRuleName")
fn ffi_update_rule_name(rule_id: Int, name: String) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "addAssignment")
fn ffi_add_assignment(
  rule_id: Int,
  weekday: Int,
  shift_time: Int,
  group_id: Int,
  member_index: Int,
) -> promise.Promise(Int)

@external(javascript, "../ffi.js", "deleteAssignment")
fn ffi_delete_assignment(assignment_id: Int) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "getCalendarState")
fn ffi_get_calendar_state(plan_id: Int) -> promise.Promise(#(Bool, Int, Int))

@external(javascript, "../ffi.js", "updateInitialDelta")
fn ffi_update_initial_delta(
  plan_id: Int,
  initial_delta: Int,
) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "deleteFutureShifts")
fn ffi_delete_future_shifts(
  plan_id: Int,
  year: Int,
  month: Int,
) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "generateAndSaveShift")
fn ffi_generate_and_save_shift(
  plan_id: Int,
  skips: List(Bool),
  year: Int,
  month: Int,
  use_initial_delta: Bool,
  initial_delta: Int,
) -> promise.Promise(Nil)

@external(javascript, "../ffi.js", "deriveMonthlyShift")
fn ffi_derive_monthly_shift(
  plan_id: Int,
  target_year: Int,
  target_month: Int,
) -> promise.Promise(List(#(String, List(#(List(String), List(String))))))

pub type Plan {
  Plan(id: Int, name: String)
}

pub type ActiveView {
  CalendarView
  ConfigView
}

pub type SelectedPlan {
  NoPlan
  SelectedPlan(id: Int)
}

pub type LoadState {
  Idle
  Loading
  Ready
  Failed(message: String)
}

pub type Remote(data) {
  NotAsked
  LoadingData
  Loaded(data: data)
  FailedData(message: String)
}

pub type StaffMember {
  StaffMember(id: Int, name: String, sort_order: Int)
}

pub type StaffGroup {
  StaffGroup(id: Int, name: String, members: List(StaffMember))
}

pub type Assignment {
  Assignment(
    id: Int,
    weekday: Int,
    shift_time: Int,
    group_id: Int,
    member_index: Int,
  )
}

pub type WeeklyRule {
  WeeklyRule(id: Int, name: String, assignments: List(Assignment))
}

pub type PlanConfig {
  PlanConfig(plan: Plan, groups: List(StaffGroup), rules: List(WeeklyRule))
}

pub type DailyShift {
  DailyShift(morning: List(String), afternoon: List(String))
}

pub type WeekInfo {
  WeekInfo(status: String, days: List(DailyShift))
}

pub type MonthlyShift {
  MonthlyShift(weeks: List(WeekInfo))
}

pub type CalendarMeta {
  CalendarMissing
  CalendarPresent(initial_delta: Int, base_abs_week: Int)
}

pub type AssignmentDraft {
  AssignmentDraft(
    weekday: Int,
    shift_time: Int,
    group_id: Int,
    member_index: Int,
  )
}

pub type NamingAction {
  CreatePlanName
  AddGroupName(plan_id: Int)
  RenameGroupName(group_id: Int)
  AddMemberName(group_id: Int)
  RenameMemberName(member_id: Int)
  AddRuleName(plan_id: Int)
  RenameRuleName(rule_id: Int)
}

pub type ModalState {
  HiddenModal
  NamingModal(action: NamingAction, title: String, value: String)
  AssignmentModal(rule_id: Int, weekday: Int, shift_time: Int)
}

pub type Msg {
  LoadPlans
  PlansLoaded(List(#(Int, String)))
  PlansFailed
  SelectPlan(String)
  ShowCalendar
  ShowConfig
  PrevMonth
  NextMonth
  ConfigLoaded(
    #(
      #(Int, String),
      List(#(Int, String, List(#(Int, String, Int)))),
      List(#(Int, String, List(#(Int, Int, Int, Int, Int)))),
    ),
  )
  ConfigFailed
  CalendarLoaded(List(#(String, List(#(List(String), List(String))))))
  CalendarFailed
  CalendarMetaLoaded(#(Bool, Int, Int))
  CalendarMetaFailed
  PromptFor(NamingAction, String, String)
  CreatePlanCreated(Int)
  OperationCompleted(String)
  OperationFailed(String)
  OpenAssignmentModal(Int, Int, Int)
  UpdateModalText(String)
  CloseModal
  SubmitModal
  AddGroup
  AddRule
  RenameGroup(Int, String)
  RenameMember(Int, String)
  RenameRule(Int, String)
  AddMember(Int)
  DeleteGroup(Int)
  DeleteMember(Int)
  DeleteRule(Int)
  DeleteAssignment(Int)
  UpdateAssignmentWeekday(Int, String)
  UpdateAssignmentShiftTime(Int, String)
  UpdateAssignmentGroup(Int, String)
  UpdateAssignmentMember(Int, String)
  AddAssignmentToRule(Int)
  UpdateInitialDeltaInput(String)
  SaveInitialDelta
  GenerateSchedule
  ResetFuture
  ToggleWeekSkip(String, Bool)
}

pub type Model {
  Model(
    plans: List(Plan),
    selected_plan: SelectedPlan,
    active_view: ActiveView,
    year: Int,
    month: Int,
    plan_load_state: LoadState,
    config_state: Remote(PlanConfig),
    calendar_state: Remote(MonthlyShift),
    calendar_meta_state: Remote(CalendarMeta),
    calendar_grid: List(#(String, List(#(Int, Bool)))),
    pending_skips: List(#(String, Bool)),
    assignment_drafts: List(#(Int, AssignmentDraft)),
    initial_delta_input: String,
    notice: String,
    modal_state: ModalState,
  )
}

pub fn init(_) -> #(Model, effect.Effect(Msg)) {
  let #(year, month) = ffi_current_date()
  let grid = ffi_calendar_grid(year, month)

  #(
    Model(
      [],
      NoPlan,
      CalendarView,
      year,
      month,
      Loading,
      NotAsked,
      NotAsked,
      NotAsked,
      grid,
      [],
      [],
      "0",
      "",
      HiddenModal,
    ),
    load_plans_effect(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    LoadPlans -> #(
      Model(..model, plan_load_state: Loading),
      load_plans_effect(),
    )
    PlansLoaded(raw_plans) -> {
      let plans = raw_plans |> list.map(plan_from_tuple)
      let selected_plan = keep_or_pick_plan(model.selected_plan, plans)
      let next_model =
        Model(
          ..model,
          plans: plans,
          selected_plan: selected_plan,
          plan_load_state: Ready,
          config_state: remote_for_selection(selected_plan),
          calendar_state: remote_for_selection(selected_plan),
          calendar_meta_state: remote_for_selection(selected_plan),
          notice: "",
        )
      #(next_model, effects_for_selection(next_model))
    }
    PlansFailed -> #(
      Model(..model, plan_load_state: Failed("Failed to load plans.")),
      effect.none(),
    )
    SelectPlan(value) -> {
      let selected_plan = parse_selected_plan(value)
      let next_model =
        Model(
          ..model,
          selected_plan: selected_plan,
          config_state: remote_for_selection(selected_plan),
          calendar_state: remote_for_selection(selected_plan),
          calendar_meta_state: remote_for_selection(selected_plan),
          pending_skips: [],
          assignment_drafts: [],
          notice: "",
        )
      #(next_model, effects_for_selection(next_model))
    }
    ShowCalendar -> #(Model(..model, active_view: CalendarView), effect.none())
    ShowConfig -> #(Model(..model, active_view: ConfigView), effect.none())
    PrevMonth -> {
      let next_model = shift_month(model, -1)
      #(next_model, calendar_effects_for_selection(next_model))
    }
    NextMonth -> {
      let next_model = shift_month(model, 1)
      #(next_model, calendar_effects_for_selection(next_model))
    }
    ConfigLoaded(payload) -> {
      let config = plan_config_from_payload(payload)
      let drafts = ensure_assignment_drafts(model.assignment_drafts, config)
      #(
        Model(..model, config_state: Loaded(config), assignment_drafts: drafts),
        effect.none(),
      )
    }
    ConfigFailed -> #(
      Model(..model, config_state: FailedData("Failed to load config.")),
      effect.none(),
    )
    CalendarLoaded(payload) -> #(
      Model(
        ..model,
        calendar_state: Loaded(monthly_shift_from_payload(payload)),
      ),
      effect.none(),
    )
    CalendarFailed -> #(
      Model(..model, calendar_state: FailedData("Failed to load calendar.")),
      effect.none(),
    )
    CalendarMetaLoaded(payload) -> {
      let meta = calendar_meta_from_payload(payload)
      let initial_delta_input = case meta {
        CalendarPresent(initial_delta:, ..) -> int.to_string(initial_delta)
        CalendarMissing -> model.initial_delta_input
      }
      #(
        Model(
          ..model,
          calendar_meta_state: Loaded(meta),
          initial_delta_input: initial_delta_input,
        ),
        effect.none(),
      )
    }
    CalendarMetaFailed -> #(
      Model(
        ..model,
        calendar_meta_state: FailedData("Failed to load calendar settings."),
      ),
      effect.none(),
    )
    PromptFor(action, title, default_value) -> #(
      Model(
        ..model,
        modal_state: NamingModal(action, title, default_value),
      ),
      effect.none(),
    )
    CreatePlanCreated(plan_id) -> {
      let next_model =
        Model(
          ..model,
          selected_plan: SelectedPlan(plan_id),
          plan_load_state: Loading,
          modal_state: HiddenModal,
        )
      #(next_model, load_plans_effect())
    }
    OperationCompleted(message) -> {
      let next_model =
        Model(..model, notice: message, modal_state: HiddenModal)
      #(next_model, refresh_selected_effect(next_model))
    }
    OperationFailed(message) -> #(
      Model(..model, notice: message),
      effect.none(),
    )
    OpenAssignmentModal(rule_id, weekday, shift_time) -> #(
      Model(
        ..model,
        modal_state: AssignmentModal(rule_id, weekday, shift_time),
        assignment_drafts: update_assignment_draft(
          rule_id,
          model.assignment_drafts,
          fn(draft) {
            AssignmentDraft(
              weekday,
              shift_time,
              draft.group_id,
              draft.member_index,
            )
          },
        ),
      ),
      effect.none(),
    )
    UpdateModalText(value) -> #(
      Model(..model, modal_state: update_modal_text(model.modal_state, value)),
      effect.none(),
    )
    CloseModal -> #(
      Model(..model, modal_state: HiddenModal),
      effect.none(),
    )
    SubmitModal ->
      case model.modal_state {
        NamingModal(action, _, value) ->
          case string.trim(value) {
            "" -> #(
              Model(..model, modal_state: HiddenModal),
              effect.none(),
            )
            trimmed -> #(
              Model(..model, notice: "", modal_state: HiddenModal),
              naming_action_effect(action, trimmed),
            )
          }
        AssignmentModal(rule_id, _, _) -> #(
          Model(..model, modal_state: HiddenModal),
          add_assignment_effect(
            rule_id,
            model.config_state,
            model.assignment_drafts,
          ),
        )
        HiddenModal -> #(model, effect.none())
      }
    AddGroup ->
      case model.selected_plan {
        SelectedPlan(plan_id) -> #(
          Model(
            ..model,
            modal_state: NamingModal(
              AddGroupName(plan_id),
              "New Group Name",
              "New Group",
            ),
          ),
          effect.none(),
        )
        NoPlan -> #(
          Model(..model, notice: "Select a plan first."),
          effect.none(),
        )
      }
    AddRule ->
      case model.selected_plan {
        SelectedPlan(plan_id) -> #(
          Model(
            ..model,
            modal_state: NamingModal(
              AddRuleName(plan_id),
              "New Rule Name",
              "Week " <> next_rule_label(model.config_state),
            ),
          ),
          effect.none(),
        )
        NoPlan -> #(
          Model(..model, notice: "Select a plan first."),
          effect.none(),
        )
      }
    RenameGroup(group_id, current_name) -> #(
      Model(
        ..model,
        modal_state: NamingModal(
          RenameGroupName(group_id),
          "Rename Group",
          current_name,
        ),
      ),
      effect.none(),
    )
    RenameMember(member_id, current_name) -> #(
      Model(
        ..model,
        modal_state: NamingModal(
          RenameMemberName(member_id),
          "Rename Member",
          current_name,
        ),
      ),
      effect.none(),
    )
    RenameRule(rule_id, current_name) -> #(
      Model(
        ..model,
        modal_state: NamingModal(
          RenameRuleName(rule_id),
          "Rename Rule",
          current_name,
        ),
      ),
      effect.none(),
    )
    AddMember(group_id) -> #(
      Model(
        ..model,
        modal_state: NamingModal(
          AddMemberName(group_id),
          "New Member Name",
          "New Member",
        ),
      ),
      effect.none(),
    )
    DeleteGroup(group_id) -> #(
      model,
      unit_effect(
        ffi_delete_staff_group(group_id),
        "Group deleted.",
        "Failed to delete group.",
      ),
    )
    DeleteMember(member_id) -> #(
      model,
      unit_effect(
        ffi_delete_staff_member(member_id),
        "Member deleted.",
        "Failed to delete member.",
      ),
    )
    DeleteRule(rule_id) -> #(
      model,
      unit_effect(
        ffi_delete_weekly_rule(rule_id),
        "Rule deleted.",
        "Failed to delete rule.",
      ),
    )
    DeleteAssignment(assignment_id) -> #(
      model,
      unit_effect(
        ffi_delete_assignment(assignment_id),
        "Assignment deleted.",
        "Failed to delete assignment.",
      ),
    )
    UpdateAssignmentWeekday(rule_id, value) -> #(
      Model(
        ..model,
        assignment_drafts: update_assignment_draft(
          rule_id,
          model.assignment_drafts,
          fn(draft) {
            AssignmentDraft(
              parse_int_with_default(value, draft.weekday),
              draft.shift_time,
              draft.group_id,
              draft.member_index,
            )
          },
        ),
      ),
      effect.none(),
    )
    UpdateAssignmentShiftTime(rule_id, value) -> #(
      Model(
        ..model,
        assignment_drafts: update_assignment_draft(
          rule_id,
          model.assignment_drafts,
          fn(draft) {
            AssignmentDraft(
              draft.weekday,
              parse_int_with_default(value, draft.shift_time),
              draft.group_id,
              draft.member_index,
            )
          },
        ),
      ),
      effect.none(),
    )
    UpdateAssignmentGroup(rule_id, value) -> #(
      Model(
        ..model,
        assignment_drafts: update_assignment_draft(
          rule_id,
          model.assignment_drafts,
          fn(draft) {
            AssignmentDraft(
              draft.weekday,
              draft.shift_time,
              parse_int_with_default(value, draft.group_id),
              0,
            )
          },
        ),
      ),
      effect.none(),
    )
    UpdateAssignmentMember(rule_id, value) -> #(
      Model(
        ..model,
        assignment_drafts: update_assignment_draft(
          rule_id,
          model.assignment_drafts,
          fn(draft) {
            AssignmentDraft(
              draft.weekday,
              draft.shift_time,
              draft.group_id,
              parse_int_with_default(value, draft.member_index),
            )
          },
        ),
      ),
      effect.none(),
    )
    AddAssignmentToRule(rule_id) -> #(
      model,
      add_assignment_effect(
        rule_id,
        model.config_state,
        model.assignment_drafts,
      ),
    )
    UpdateInitialDeltaInput(value) -> #(
      Model(..model, initial_delta_input: value),
      effect.none(),
    )
    SaveInitialDelta ->
      case
        model.selected_plan,
        model.calendar_meta_state,
        parse_non_negative_int(model.initial_delta_input)
      {
        SelectedPlan(plan_id), Loaded(CalendarPresent(..)), Ok(initial_delta) -> #(
          model,
          unit_effect(
            ffi_update_initial_delta(plan_id, initial_delta),
            "Initial delta updated.",
            "Failed to update initial delta.",
          ),
        )
        SelectedPlan(_), Loaded(CalendarMissing), Ok(_) -> #(
          Model(
            ..model,
            notice: "Initial delta will be used when the calendar is first generated.",
          ),
          effect.none(),
        )
        _, _, _ -> #(
          Model(..model, notice: "Initial delta must be a non-negative number."),
          effect.none(),
        )
      }
    GenerateSchedule -> #(model, generate_schedule_effect(model))
    ResetFuture -> #(model, reset_future_effect(model))
    ToggleWeekSkip(week_key, is_checked) -> #(
      Model(
        ..model,
        pending_skips: set_pending_skip(
          model.pending_skips,
          week_key,
          is_checked,
        ),
      ),
      effect.none(),
    )
  }
}

fn update_modal_text(modal_state: ModalState, value: String) -> ModalState {
  case modal_state {
    NamingModal(action, title, _) -> NamingModal(action, title, value)
    _ -> modal_state
  }
}

fn load_plans_effect() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_list_plans()
    |> promise.tap(fn(plans) { dispatch(PlansLoaded(plans)) })
    |> promise.rescue(fn(_) {
      dispatch(PlansFailed)
      []
    })
    Nil
  })
}

fn naming_action_effect(
  action: NamingAction,
  value: String,
) -> effect.Effect(Msg) {
  case action {
    CreatePlanName ->
      effect.from(fn(dispatch) {
        ffi_create_plan(value)
        |> promise.tap(fn(plan_id) { dispatch(CreatePlanCreated(plan_id)) })
        |> promise.rescue(fn(_) {
          dispatch(OperationFailed("Failed to create plan."))
          0
        })
        Nil
      })
    AddGroupName(plan_id) ->
      unit_effect(
        ffi_add_staff_group(plan_id, value),
        "Group created.",
        "Failed to create group.",
      )
    RenameGroupName(group_id) ->
      unit_effect(
        ffi_update_group_name(group_id, value),
        "Group renamed.",
        "Failed to rename group.",
      )
    AddMemberName(group_id) ->
      unit_effect(
        ffi_add_staff_member(group_id, value),
        "Member added.",
        "Failed to add member.",
      )
    RenameMemberName(member_id) ->
      unit_effect(
        ffi_update_member_name(member_id, value),
        "Member renamed.",
        "Failed to rename member.",
      )
    AddRuleName(plan_id) ->
      unit_effect(
        ffi_add_weekly_rule(plan_id, value),
        "Rule created.",
        "Failed to create rule.",
      )
    RenameRuleName(rule_id) ->
      unit_effect(
        ffi_update_rule_name(rule_id, value),
        "Rule renamed.",
        "Failed to rename rule.",
      )
  }
}

fn unit_effect(
  work: promise.Promise(a),
  success_message: String,
  failure_message: String,
) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    work
    |> promise.tap(fn(_) { dispatch(OperationCompleted(success_message)) })
    |> promise.rescue(fn(_) {
      dispatch(OperationFailed(failure_message))
      panic as "ignored"
    })
    Nil
  })
}

fn add_assignment_effect(
  rule_id: Int,
  config_state: Remote(PlanConfig),
  drafts: List(#(Int, AssignmentDraft)),
) -> effect.Effect(Msg) {
  case config_state {
    Loaded(config) -> {
      let draft = assignment_draft_for_rule(rule_id, drafts, config.groups)
      unit_effect(
        ffi_add_assignment(
          rule_id,
          draft.weekday,
          draft.shift_time,
          draft.group_id,
          draft.member_index,
        ),
        "Assignment added.",
        "Failed to add assignment.",
      )
    }
    _ -> effect.none()
  }
}

fn generate_schedule_effect(model: Model) -> effect.Effect(Msg) {
  case model.selected_plan, parse_non_negative_int(model.initial_delta_input) {
    SelectedPlan(plan_id), Ok(initial_delta) ->
      effect.from(fn(dispatch) {
        let #(use_initial_delta, initial_delta_value) =
          generation_delta(model.calendar_meta_state, initial_delta)
        let skips = generation_skips(model)
        ffi_generate_and_save_shift(
          plan_id,
          skips,
          model.year,
          model.month,
          use_initial_delta,
          initial_delta_value,
        )
        |> promise.tap(fn(_) {
          dispatch(OperationCompleted("Schedule generated."))
        })
        |> promise.rescue(fn(_) {
          dispatch(OperationFailed("Failed to generate schedule."))
          Nil
        })
        Nil
      })
    SelectedPlan(_), Error(_) ->
      effect.from(fn(dispatch) {
        dispatch(OperationFailed("Initial delta must be a non-negative number."))
        Nil
      })
    _, _ -> effect.none()
  }
}

fn reset_future_effect(model: Model) -> effect.Effect(Msg) {
  case model.selected_plan {
    SelectedPlan(plan_id) ->
      effect.from(fn(dispatch) {
        ffi_delete_future_shifts(plan_id, model.year, model.month)
        |> promise.tap(fn(_) {
          dispatch(OperationCompleted("Future shifts deleted."))
        })
        |> promise.rescue(fn(_) {
          dispatch(OperationFailed("Failed to delete future shifts."))
          Nil
        })
        Nil
      })
    NoPlan -> effect.none()
  }
}

fn effects_for_selection(model: Model) -> effect.Effect(Msg) {
  case model.selected_plan {
    SelectedPlan(plan_id) ->
      effect.batch([
        load_config_effect(plan_id),
        load_calendar_effect(plan_id, model.year, model.month),
        load_calendar_meta_effect(plan_id),
      ])
    NoPlan -> effect.none()
  }
}

fn refresh_selected_effect(model: Model) -> effect.Effect(Msg) {
  effects_for_selection(model)
}

fn calendar_effects_for_selection(model: Model) -> effect.Effect(Msg) {
  case model.selected_plan {
    SelectedPlan(plan_id) ->
      load_calendar_effect(plan_id, model.year, model.month)
    NoPlan -> effect.none()
  }
}

fn load_config_effect(plan_id: Int) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_get_plan_config(plan_id)
    |> promise.tap(fn(payload) { dispatch(ConfigLoaded(payload)) })
    |> promise.rescue(fn(_) {
      dispatch(ConfigFailed)
      #(#(0, ""), [], [])
    })
    Nil
  })
}

fn load_calendar_effect(
  plan_id: Int,
  year: Int,
  month: Int,
) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_derive_monthly_shift(plan_id, year, month)
    |> promise.tap(fn(payload) { dispatch(CalendarLoaded(payload)) })
    |> promise.rescue(fn(_) {
      dispatch(CalendarFailed)
      []
    })
    Nil
  })
}

fn load_calendar_meta_effect(plan_id: Int) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    ffi_get_calendar_state(plan_id)
    |> promise.tap(fn(payload) { dispatch(CalendarMetaLoaded(payload)) })
    |> promise.rescue(fn(_) {
      dispatch(CalendarMetaFailed)
      #(False, 0, 0)
    })
    Nil
  })
}

fn shift_month(model: Model, delta: Int) -> Model {
  let raw_month = model.month + delta
  let #(year, month) = case raw_month {
    -1 -> #(model.year - 1, 11)
    12 -> #(model.year + 1, 0)
    _ -> #(model.year, raw_month)
  }

  Model(
    ..model,
    year: year,
    month: month,
    calendar_grid: ffi_calendar_grid(year, month),
    calendar_state: case model.selected_plan {
      SelectedPlan(_) -> LoadingData
      NoPlan -> NotAsked
    },
    pending_skips: [],
  )
}

fn remote_for_selection(selected_plan: SelectedPlan) -> Remote(a) {
  case selected_plan {
    SelectedPlan(_) -> LoadingData
    NoPlan -> NotAsked
  }
}

fn plan_from_tuple(plan: #(Int, String)) -> Plan {
  let #(id, name) = plan
  Plan(id:, name:)
}

fn keep_or_pick_plan(
  selected_plan: SelectedPlan,
  plans: List(Plan),
) -> SelectedPlan {
  case selected_plan {
    SelectedPlan(id) ->
      case list.any(plans, fn(plan) { plan.id == id }) {
        True -> selected_plan
        False -> first_plan_or_none(plans)
      }
    NoPlan -> first_plan_or_none(plans)
  }
}

fn first_plan_or_none(plans: List(Plan)) -> SelectedPlan {
  case plans {
    [Plan(id:, ..), ..] -> SelectedPlan(id)
    [] -> NoPlan
  }
}

fn parse_selected_plan(value: String) -> SelectedPlan {
  case int.parse(value) {
    Ok(id) -> SelectedPlan(id)
    Error(_) -> NoPlan
  }
}

pub fn selected_plan_value(selected_plan: SelectedPlan) -> String {
  case selected_plan {
    NoPlan -> ""
    SelectedPlan(id) -> int.to_string(id)
  }
}

pub fn plan_placeholder(load_state: LoadState) -> String {
  case load_state {
    Loading -> "Loading plans..."
    Failed(_) -> "Failed to load plans"
    _ -> "Select Plan..."
  }
}

fn plan_option(selected_plan: SelectedPlan, plan: Plan) {
  option(
    [
      attribute.value(int.to_string(plan.id)),
      attribute.selected(is_selected_plan(selected_plan, plan.id)),
    ],
    plan.name,
  )
}

fn is_selected_plan(selected_plan: SelectedPlan, plan_id: Int) -> Bool {
  case selected_plan {
    SelectedPlan(selected_id) -> selected_id == plan_id
    NoPlan -> False
  }
}

pub fn has_selected_plan(selected_plan: SelectedPlan) -> Bool {
  case selected_plan {
    SelectedPlan(_) -> True
    NoPlan -> False
  }
}

fn view_button_classes(is_active: Bool) {
  attribute.classes([#("view-btn", True), #("active", is_active)])
}

pub fn month_label(year: Int, month: Int) -> String {
  int.to_string(year) <> " / " <> month_name(month)
}

fn month_name(month: Int) -> String {
  case month {
    0 -> "January"
    1 -> "February"
    2 -> "March"
    3 -> "April"
    4 -> "May"
    5 -> "June"
    6 -> "July"
    7 -> "August"
    8 -> "September"
    9 -> "October"
    10 -> "November"
    _ -> "December"
  }
}

fn next_rule_label(config_state: Remote(PlanConfig)) -> String {
  case config_state {
    Loaded(config) -> int.to_string(list.length(config.rules) + 1)
    _ -> "1"
  }
}

fn plan_config_from_payload(
  payload: #(
    #(Int, String),
    List(#(Int, String, List(#(Int, String, Int)))),
    List(#(Int, String, List(#(Int, Int, Int, Int, Int)))),
  ),
) -> PlanConfig {
  let #(plan_payload, group_payloads, rule_payloads) = payload
  let #(plan_id, plan_name) = plan_payload

  PlanConfig(
    plan: Plan(plan_id, plan_name),
    groups: group_payloads |> list.map(group_from_payload),
    rules: rule_payloads |> list.map(rule_from_payload),
  )
}

fn group_from_payload(
  group_payload: #(Int, String, List(#(Int, String, Int))),
) -> StaffGroup {
  let #(id, name, member_payloads) = group_payload
  StaffGroup(
    id:,
    name:,
    members: member_payloads |> list.map(member_from_payload),
  )
}

fn member_from_payload(member_payload: #(Int, String, Int)) -> StaffMember {
  let #(id, name, sort_order) = member_payload
  StaffMember(id:, name:, sort_order:)
}

fn rule_from_payload(
  rule_payload: #(Int, String, List(#(Int, Int, Int, Int, Int))),
) -> WeeklyRule {
  let #(id, name, assignment_payloads) = rule_payload
  WeeklyRule(
    id:,
    name:,
    assignments: assignment_payloads |> list.map(assignment_from_payload),
  )
}

fn assignment_from_payload(
  assignment_payload: #(Int, Int, Int, Int, Int),
) -> Assignment {
  let #(id, weekday, shift_time, group_id, member_index) = assignment_payload
  Assignment(id:, weekday:, shift_time:, group_id:, member_index:)
}

fn monthly_shift_from_payload(
  payload: List(#(String, List(#(List(String), List(String))))),
) -> MonthlyShift {
  MonthlyShift(payload |> list.map(week_from_payload))
}

fn week_from_payload(
  week_payload: #(String, List(#(List(String), List(String)))),
) -> WeekInfo {
  let #(status, day_payloads) = week_payload
  WeekInfo(status:, days: day_payloads |> list.map(day_from_payload))
}

fn day_from_payload(day_payload: #(List(String), List(String))) -> DailyShift {
  let #(morning, afternoon) = day_payload
  DailyShift(morning:, afternoon:)
}

fn calendar_meta_from_payload(payload: #(Bool, Int, Int)) -> CalendarMeta {
  let #(exists, initial_delta, base_abs_week) = payload
  case exists {
    True -> CalendarPresent(initial_delta:, base_abs_week:)
    False -> CalendarMissing
  }
}

fn ensure_assignment_drafts(
  drafts: List(#(Int, AssignmentDraft)),
  config: PlanConfig,
) -> List(#(Int, AssignmentDraft)) {
  config.rules
  |> list.fold(drafts, fn(acc, rule) {
    case has_draft(rule.id, acc) {
      True -> acc
      False -> [#(rule.id, default_assignment_draft(config.groups)), ..acc]
    }
  })
}

fn has_draft(rule_id: Int, drafts: List(#(Int, AssignmentDraft))) -> Bool {
  list.any(drafts, fn(entry) {
    let #(id, _) = entry
    id == rule_id
  })
}

fn default_assignment_draft(groups: List(StaffGroup)) -> AssignmentDraft {
  case groups {
    [StaffGroup(id:, ..), ..] ->
      AssignmentDraft(weekday: 0, shift_time: 0, group_id: id, member_index: 0)
    [] ->
      AssignmentDraft(weekday: 0, shift_time: 0, group_id: 0, member_index: 0)
  }
}

pub fn assignment_draft_for_rule(
  rule_id: Int,
  drafts: List(#(Int, AssignmentDraft)),
  groups: List(StaffGroup),
) -> AssignmentDraft {
  case
    list.find(drafts, fn(entry) {
      let #(id, _) = entry
      id == rule_id
    })
  {
    Ok(#(_, draft)) -> normalize_assignment_draft(draft, groups)
    Error(_) -> default_assignment_draft(groups)
  }
}

fn normalize_assignment_draft(
  draft: AssignmentDraft,
  groups: List(StaffGroup),
) -> AssignmentDraft {
  let group_id = valid_group_id(draft.group_id, groups)
  let members = members_for_group(groups, group_id)
  AssignmentDraft(
    draft.weekday,
    draft.shift_time,
    group_id,
    clamp_member_index(draft.member_index, members),
  )
}

fn valid_group_id(group_id: Int, groups: List(StaffGroup)) -> Int {
  case list.find(groups, fn(group) { group.id == group_id }) {
    Ok(group) -> group.id
    Error(_) ->
      case groups {
        [StaffGroup(id:, ..), ..] -> id
        [] -> 0
      }
  }
}

pub fn members_for_group(
  groups: List(StaffGroup),
  group_id: Int,
) -> List(StaffMember) {
  case list.find(groups, fn(group) { group.id == group_id }) {
    Ok(group) -> group.members
    Error(_) -> []
  }
}

pub fn clamp_member_index(index: Int, members: List(StaffMember)) -> Int {
  let max_index = list.length(members) - 1
  case max_index < 0 {
    True -> 0
    False ->
      case index < 0 {
        True -> 0
        False ->
          case index > max_index {
            True -> max_index
            False -> index
          }
      }
  }
}

fn update_assignment_draft(
  rule_id: Int,
  drafts: List(#(Int, AssignmentDraft)),
  updater: fn(AssignmentDraft) -> AssignmentDraft,
) -> List(#(Int, AssignmentDraft)) {
  case drafts {
    [] -> [#(rule_id, updater(AssignmentDraft(0, 0, 0, 0)))]
    [#(id, draft), ..rest] if id == rule_id -> [#(id, updater(draft)), ..rest]
    [entry, ..rest] -> [
      entry,
      ..update_assignment_draft(rule_id, rest, updater)
    ]
  }
}

fn parse_int_with_default(value: String, default: Int) -> Int {
  case int.parse(value) {
    Ok(parsed) -> parsed
    Error(_) -> default
  }
}

fn parse_non_negative_int(value: String) -> Result(Int, Nil) {
  case int.parse(value) {
    Ok(parsed) if parsed >= 0 -> Ok(parsed)
    _ -> Error(Nil)
  }
}

pub fn assignment_label(assignment: Assignment, groups: List(StaffGroup)) -> String {
  let group_name = case
    list.find(groups, fn(group) { group.id == assignment.group_id })
  {
    Ok(group) -> group.name
    Error(_) -> "Unknown Group"
  }
  day_name(assignment.weekday)
  <> " "
  <> shift_time_name(assignment.shift_time)
  <> " -> "
  <> group_name
  <> " #"
  <> int.to_string(assignment.member_index)
}

pub fn day_name(day_index: Int) -> String {
  case day_index {
    0 -> "Mon"
    1 -> "Tue"
    2 -> "Wed"
    3 -> "Thu"
    4 -> "Fri"
    5 -> "Sat"
    _ -> "Sun"
  }
}

pub fn shift_time_name(shift_time: Int) -> String {
  case shift_time {
    0 -> "AM"
    _ -> "PM"
  }
}

pub fn day_shift_at(
  calendar_state: Remote(MonthlyShift),
  week_index: Int,
  day_index: Int,
) -> DailyShift {
  case calendar_state {
    Loaded(monthly_shift) ->
      case nth(monthly_shift.weeks, week_index) {
        Ok(week) ->
          case nth(week.days, day_index) {
            Ok(day) -> day
            Error(_) -> DailyShift([], [])
          }
        Error(_) -> DailyShift([], [])
      }
    _ -> DailyShift([], [])
  }
}

pub type WeekDisplayState {
  PendingActive
  PendingSkip
  FixedActive
  FixedSkip
}

pub fn week_display_state(
  model: Model,
  week_index: Int,
  week_key: String,
) -> WeekDisplayState {
  case model.calendar_state {
    Loaded(monthly_shift) ->
      case nth(monthly_shift.weeks, week_index) {
        Ok(week) ->
          case week.status {
            "Active" -> FixedActive
            "Skipped" -> FixedSkip
            _ ->
              case pending_skip_value(model.pending_skips, week_key) {
                True -> PendingSkip
                False -> PendingActive
              }
          }
        Error(_) ->
          case pending_skip_value(model.pending_skips, week_key) {
            True -> PendingSkip
            False -> PendingActive
          }
      }
    _ ->
      case pending_skip_value(model.pending_skips, week_key) {
        True -> PendingSkip
        False -> PendingActive
      }
  }
}

fn nth(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [], _ -> Error(Nil)
    [item, ..], 0 -> Ok(item)
    [_, ..rest], remaining if remaining > 0 -> nth(rest, remaining - 1)
    _, _ -> Error(Nil)
  }
}

pub fn week_state_is_fixed(state: WeekDisplayState) -> Bool {
  case state {
    FixedActive -> True
    FixedSkip -> True
    _ -> False
  }
}

pub fn week_state_is_skip(state: WeekDisplayState) -> Bool {
  case state {
    PendingSkip -> True
    FixedSkip -> True
    _ -> False
  }
}

pub fn week_state_label(state: WeekDisplayState) -> String {
  case state {
    PendingActive -> "ACTIVE"
    PendingSkip -> "SKIP"
    FixedActive -> "ACTIVE (FIXED)"
    FixedSkip -> "SKIPPED (FIXED)"
  }
}

pub fn status_text_class(state: WeekDisplayState) -> String {
  case state {
    PendingActive -> "status-text text-active"
    PendingSkip -> "status-text text-skip"
    FixedActive -> "status-text text-fixed-active"
    FixedSkip -> "status-text text-fixed-skip"
  }
}

fn pending_skip_value(
  pending_skips: List(#(String, Bool)),
  week_key: String,
) -> Bool {
  case
    list.find(pending_skips, fn(entry) {
      let #(key, _) = entry
      key == week_key
    })
  {
    Ok(#(_, value)) -> value
    Error(_) -> False
  }
}

fn set_pending_skip(
  pending_skips: List(#(String, Bool)),
  week_key: String,
  is_checked: Bool,
) -> List(#(String, Bool)) {
  case pending_skips {
    [] -> [#(week_key, is_checked)]
    [#(key, _), ..rest] if key == week_key -> [#(week_key, is_checked), ..rest]
    [entry, ..rest] -> [entry, ..set_pending_skip(rest, week_key, is_checked)]
  }
}

pub fn can_generate(model: Model) -> Bool {
  case model.selected_plan {
    NoPlan -> False
    SelectedPlan(_) ->
      list.any(model.calendar_grid, fn(entry) {
        let #(week_key, _) = entry
        !week_state_is_fixed(week_display_state(
          model,
          week_index_for_key(model.calendar_grid, week_key, 0),
          week_key,
        ))
      })
  }
}

fn week_index_for_key(
  weeks: List(#(String, List(#(Int, Bool)))),
  week_key: String,
  start: Int,
) -> Int {
  case weeks {
    [] -> 0
    [#(key, _), ..rest] ->
      case key == week_key {
        True -> start
        False -> week_index_for_key(rest, week_key, start + 1)
      }
  }
}

fn generation_skips(model: Model) -> List(Bool) {
  model.calendar_grid
  |> list.index_map(fn(entry, index) {
    let #(week_key, _) = entry
    week_state_is_skip(week_display_state(model, index, week_key))
  })
}

fn generation_delta(
  calendar_meta_state: Remote(CalendarMeta),
  fallback: Int,
) -> #(Bool, Int) {
  case calendar_meta_state {
    Loaded(CalendarMissing) -> #(True, fallback)
    _ -> #(False, 0)
  }
}

pub fn calendar_settings_summary(
  calendar_meta_state: Remote(CalendarMeta),
) -> String {
  case calendar_meta_state {
    Loaded(CalendarPresent(initial_delta:, base_abs_week:)) ->
      "Calendar exists. Initial delta: "
      <> int.to_string(initial_delta)
      <> ", Base week: "
      <> int.to_string(base_abs_week)
    Loaded(CalendarMissing) ->
      "No calendar exists yet. The initial delta below will be used for the first generation."
    LoadingData -> "Loading calendar settings..."
    FailedData(message) -> message
    NotAsked -> "Select a plan to load settings."
  }
}
