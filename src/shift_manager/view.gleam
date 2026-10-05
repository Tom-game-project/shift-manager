import gleam/int
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element, text}
import lustre/element/html.{
  button, div, h1, h2, h3, input, main as html_main, nav, option, p, section,
  select,
}
import lustre/event.{on_change, on_check, on_click, on_input}
import shift_manager/model as app_model

pub fn view(model: app_model.Model) {
  div([attribute.class("app-shell")], [
    header_view(model),
    html_main([attribute.class("main-viewport")], [
      notice_view(model.notice),
      case model.active_view {
        CalendarView -> calendar_view(model)
        ConfigView -> config_view(model)
      },
    ]),
    render_modal(model),
  ])
}

fn notice_view(notice: String) {
  case string.trim(notice) {
    "" -> div([], [])
    _ ->
      div(
        [
          attribute.class("glass-panel"),
          attribute.attribute(
            "style",
            "max-width: 1200px; margin: 0 auto 12px auto; padding: 12px 16px;",
          ),
        ],
        [p([], [text(notice)])],
      )
  }
}

fn header_view(model: app_model.Model) {
  nav([attribute.class("app-header")], [
    div([attribute.class("header-left")], [
      h1([attribute.class("app-title")], [text("Shift Manager")]),
      div([attribute.class("plan-selector")], [
        plan_select(model),
        button(
          [
            attribute.class("btn btn-sm btn-outline"),
            on_click(app_model.PromptFor(app_model.CreatePlanName, "Create New Plan", "")),
          ],
          [text("+")],
        ),
      ]),
    ]),
    div([attribute.class("view-switcher")], [
      button(
        [
          view_button_classes(model.active_view == CalendarView),
          on_click(app_model.ShowCalendar),
        ],
        [text("Viewer")],
      ),
      button(
        [
          view_button_classes(model.active_view == ConfigView),
          on_click(app_model.ShowConfig),
        ],
        [text("Config")],
      ),
    ]),
  ])
}

fn plan_select(model: app_model.Model) {
  select(
    [
      attribute.class("form-select"),
      attribute.value(app_model.selected_plan_value(model.selected_plan)),
      on_change(app_model.SelectPlan),
    ],
    [
      option([attribute.value("")], app_model.plan_placeholder(model.plan_load_state)),
      ..{
        model.plans
        |> list.map(fn(plan) { plan_option(model.selected_plan, plan) })
      }
    ],
  )
}

fn render_modal(model: app_model.Model) {
  case model.modal_state {
    app_model.HiddenModal -> div([attribute.class("modal"), attribute.attribute("style", "display:none;")], [])
    app_model.NamingModal(_, title, value) ->
      div([attribute.class("modal"), attribute.attribute("style", "display:flex;")], [
        div([attribute.class("modal-content")], [
          h3([], [text(title)]),
          input(
            [
              attribute.class("form-select modal-input"),
              attribute.value(value),
              on_input(app_model.UpdateModalText),
            ],
          ),
          div([attribute.class("modal-actions")], [
            button([attribute.class("btn btn-outline"), on_click(app_model.CloseModal)], [text("Cancel")]),
            button([attribute.class("btn btn-primary"), on_click(app_model.SubmitModal)], [text("Save")]),
          ]),
        ]),
      ])
    app_model.AssignmentModal(rule_id, weekday, shift_time) ->
      div([attribute.class("modal"), attribute.attribute("style", "display:flex;")], [
        div([attribute.class("modal-content assignment-modal")], [
          h3([], [text("Add Assignment")]),
          p([], [text(app_model.day_name(weekday) <> " " <> app_model.shift_time_name(shift_time))]),
          render_assignment_modal_body(model, rule_id),
          div([attribute.class("modal-actions")], [
            button([attribute.class("btn btn-outline"), on_click(app_model.CloseModal)], [text("Cancel")]),
            button([attribute.class("btn btn-primary"), on_click(app_model.SubmitModal)], [text("Add")]),
          ]),
        ]),
      ])
  }
}

fn calendar_view(model: app_model.Model) {
  div([attribute.class("view-section active-view")], [
    div([attribute.class("container")], [
      section([attribute.class("glass-panel calendar-controls-bar")], [
        div([attribute.class("nav-controls")], [
          button([attribute.class("btn btn-outline"), on_click(app_model.PrevMonth)], [
            text("Prev"),
          ]),
          div([attribute.class("month-label")], [
            text(app_model.month_label(model.year, model.month)),
          ]),
          button([attribute.class("btn btn-outline"), on_click(app_model.NextMonth)], [
            text("Next"),
          ]),
        ]),
        div([attribute.class("action-controls")], [
          button(
            [
              attribute.class("btn btn-primary"),
              attribute.disabled(!app_model.can_generate(model)),
              on_click(app_model.GenerateSchedule),
            ],
            [text("Generate & Save")],
          ),
          button(
            [
              attribute.class("btn btn-danger btn-sm"),
              attribute.disabled(!app_model.has_selected_plan(model.selected_plan)),
              on_click(app_model.ResetFuture),
            ],
            [text("Reset Future")],
          ),
        ]),
      ]),
      section(
        [
          attribute.class("glass-panel config-section calendar-settings-panel"),
        ],
        [
          h2([], [text("Calendar Settings")]),
          p([], [text(app_model.calendar_settings_summary(model.calendar_meta_state))]),
          div(
            [
              attribute.attribute(
                "style",
                "display:flex; gap:10px; align-items:center; margin-top:12px;",
              ),
            ],
            [
              input([
                attribute.class("form-select"),
                attribute.type_("number"),
                attribute.value(model.initial_delta_input),
                on_input(app_model.UpdateInitialDeltaInput),
              ]),
              button(
                [attribute.class("btn btn-outline"), on_click(app_model.SaveInitialDelta)],
                [text("Apply")],
              ),
            ],
          ),
        ],
      ),
      section(
        [
          attribute.class("glass-panel calendar-grid-container"),
          attribute.attribute(
            "style",
            "padding: 0; overflow: hidden; margin-top: 20px;",
          ),
        ],
        [
          div([attribute.class("calendar-header-row")], [
            div([attribute.class("cal-header-cell status-col")], [text("State")]),
            div([attribute.class("cal-header-cell")], [text("Mon")]),
            div([attribute.class("cal-header-cell")], [text("Tue")]),
            div([attribute.class("cal-header-cell")], [text("Wed")]),
            div([attribute.class("cal-header-cell")], [text("Thu")]),
            div([attribute.class("cal-header-cell")], [text("Fri")]),
            div([attribute.class("cal-header-cell")], [text("Sat")]),
            div([attribute.class("cal-header-cell")], [text("Sun")]),
          ]),
          div([attribute.class("calendar-grid")], calendar_rows(model)),
        ],
      ),
    ]),
  ])
}

fn config_view(model: app_model.Model) {
  div([attribute.class("view-section active-view")], [
    div([attribute.class("container config-container")], [
      section(
        [
          attribute.class("glass-panel config-section"),
          attribute.class("config-card"),
        ],
        [
          div([attribute.class("section-header")], [
            h2([], [text("Staff Groups")]),
            button(
              [attribute.class("btn btn-primary btn-sm"), on_click(app_model.AddGroup)],
              [text("+ Add Group")],
            ),
          ]),
          ..group_section_content(model)
        ],
      ),
      section(
        [
          attribute.class("glass-panel config-section"),
          attribute.class("config-card"),
        ],
        [
          div([attribute.class("section-header")], [
            h2([], [text("Weekly Rules")]),
            button(
              [attribute.class("btn btn-primary btn-sm"), on_click(app_model.AddRule)],
              [text("+ Add Rule")],
            ),
          ]),
          ..rule_section_content(model)
        ],
      ),
    ]),
  ])
}

fn group_section_content(model: app_model.Model) -> List(Element(app_model.Msg)) {
  case model.config_state {
    app_model.Loaded(config) -> config.groups |> list.map(render_group_card)
    app_model.LoadingData -> [p([], [text("Loading groups...")])]
    app_model.FailedData(message) -> [p([], [text(message)])]
    app_model.NotAsked -> [p([], [text("Select a plan to load config.")])]
  }
}

fn rule_section_content(model: app_model.Model) -> List(Element(app_model.Msg)) {
  case model.config_state {
    app_model.Loaded(config) ->
      config.rules
      |> list.map(fn(rule) {
        render_rule_card(rule, config.groups, model.assignment_drafts)
      })
    app_model.LoadingData -> [p([], [text("Loading rules...")])]
    app_model.FailedData(message) -> [p([], [text(message)])]
    app_model.NotAsked -> [p([], [text("Select a plan to load config.")])]
  }
}

fn render_assignment_modal_body(model: Model, rule_id: Int) {
  case model.config_state {
    app_model.Loaded(config) -> {
      let draft = app_model.assignment_draft_for_rule(rule_id, model.assignment_drafts, config.groups)
      div([attribute.class("assignment-builder assignment-builder-modal")], [
        assignment_weekday_select(rule_id, draft.weekday),
        assignment_shift_select(rule_id, draft.shift_time),
        assignment_group_select(rule_id, config.groups, draft.group_id),
        assignment_member_select(rule_id, config.groups, draft.group_id, draft.member_index),
      ])
    }
    _ -> p([], [text("Config must be loaded before adding assignments.")])
  }
}

fn render_group_card(group: app_model.StaffGroup) {
  section(
    [
      attribute.class("glass-panel config-section config-card"),
    ],
    [
      div([attribute.class("section-header")], [
        h3([], [text(group.name)]),
        div([], [
          button(
            [
              attribute.class("btn btn-outline btn-sm"),
              on_click(app_model.RenameGroup(group.id, group.name)),
            ],
            [text("Rename")],
          ),
          button(
            [
              attribute.class("btn btn-danger btn-sm"),
              on_click(app_model.DeleteGroup(group.id)),
            ],
            [text("Delete")],
          ),
          button(
            [
              attribute.class("btn btn-primary btn-sm"),
              on_click(app_model.AddMember(group.id)),
            ],
            [text("+ Member")],
          ),
        ]),
      ]),
      ..{
        case group.members {
          [] -> [p([], [text("No members yet.")])]
          members -> members |> list.map(render_member_row)
        }
      }
    ],
  )
}

fn render_member_row(member: app_model.StaffMember) {
  div(
    [attribute.class("item-row")],
    [
      p([attribute.class("item-title")], [
        text("#" <> int.to_string(member.sort_order) <> " " <> member.name),
      ]),
      div([attribute.class("item-actions")], [
        button(
          [
            attribute.class("btn btn-outline btn-sm"),
            on_click(app_model.RenameMember(member.id, member.name)),
          ],
          [text("Rename")],
        ),
        button(
          [
            attribute.class("btn btn-danger btn-sm"),
            on_click(app_model.DeleteMember(member.id)),
          ],
          [text("Delete")],
        ),
      ]),
    ],
  )
}

fn render_rule_card(
  rule: app_model.WeeklyRule,
  groups: List(StaffGroup),
  _drafts: List(#(Int, AssignmentDraft)),
) {
  section(
    [
      attribute.class("glass-panel config-section config-card"),
    ],
    [
      div([attribute.class("section-header")], [
        h3([], [text(rule.name)]),
        div([], [
          button(
            [
              attribute.class("btn btn-outline btn-sm"),
              on_click(app_model.RenameRule(rule.id, rule.name)),
            ],
            [text("Rename")],
          ),
          button(
            [
              attribute.class("btn btn-danger btn-sm"),
              on_click(app_model.DeleteRule(rule.id)),
            ],
            [text("Delete")],
          ),
        ]),
      ]),
      render_rule_matrix(rule, groups),
    ],
  )
}

fn render_rule_matrix(rule: app_model.WeeklyRule, groups: List(StaffGroup)) {
  let headers = [
    div([attribute.class("rule-matrix-header rule-matrix-corner")], [text("Time")]),
    div([attribute.class("rule-matrix-header")], [text("Mon")]),
    div([attribute.class("rule-matrix-header")], [text("Tue")]),
    div([attribute.class("rule-matrix-header")], [text("Wed")]),
    div([attribute.class("rule-matrix-header")], [text("Thu")]),
    div([attribute.class("rule-matrix-header")], [text("Fri")]),
    div([attribute.class("rule-matrix-header")], [text("Sat")]),
    div([attribute.class("rule-matrix-header")], [text("Sun")]),
  ]
  let rows =
    list.append(
      render_rule_matrix_row(rule, groups, 0, "AM"),
      render_rule_matrix_row(rule, groups, 1, "PM"),
    )

  div([attribute.class("rule-matrix")], list.append(headers, rows))
}

fn render_rule_matrix_row(
  rule: app_model.WeeklyRule,
  groups: List(StaffGroup),
  shift_time: Int,
  label: String,
) -> List(Element(app_model.Msg)) {
  [
    div([attribute.class("rule-matrix-label")], [text(label)]),
    render_rule_matrix_cell(rule, groups, 0, shift_time),
    render_rule_matrix_cell(rule, groups, 1, shift_time),
    render_rule_matrix_cell(rule, groups, 2, shift_time),
    render_rule_matrix_cell(rule, groups, 3, shift_time),
    render_rule_matrix_cell(rule, groups, 4, shift_time),
    render_rule_matrix_cell(rule, groups, 5, shift_time),
    render_rule_matrix_cell(rule, groups, 6, shift_time),
  ]
}

fn render_rule_matrix_cell(
  rule: app_model.WeeklyRule,
  groups: List(StaffGroup),
  weekday: Int,
  shift_time: Int,
) {
  let cell_assignments = assignments_for_cell(rule.assignments, weekday, shift_time)

  div(
    [attribute.class("rule-matrix-cell")],
    case cell_assignments {
      [] -> [
        p([attribute.class("rule-matrix-empty")], [text("Empty")]),
        button(
          [
            attribute.class("btn btn-outline btn-sm rule-matrix-add"),
            on_click(app_model.OpenAssignmentModal(rule.id, weekday, shift_time)),
          ],
          [text("+ Add")],
        ),
      ]
      assignments ->
        [
          button(
            [
              attribute.class("btn btn-outline btn-sm rule-matrix-add"),
              on_click(app_model.OpenAssignmentModal(rule.id, weekday, shift_time)),
            ],
            [text("+")],
          ),
          ..{
            assignments
            |> list.map(fn(assignment) {
              render_assignment_chip(assignment, groups)
            })
          }
        ]
    },
  )
}

fn assignments_for_cell(
  assignments: List(Assignment),
  weekday: Int,
  shift_time: Int,
) -> List(Assignment) {
  assignments
  |> list.filter(fn(assignment) {
    assignment.weekday == weekday && assignment.shift_time == shift_time
  })
}

fn render_assignment_chip(assignment: Assignment, groups: List(StaffGroup)) {
  button(
    [
      attribute.class("rule-assignment-chip"),
      on_click(app_model.DeleteAssignment(assignment.id)),
    ],
    [text(app_model.assignment_label(assignment, groups))],
  )
}

fn assignment_weekday_select(rule_id: Int, selected_value: Int) {
  select(
    [
      attribute.class("form-select"),
      attribute.value(int.to_string(selected_value)),
      on_change(fn(value) { app_model.UpdateAssignmentWeekday(rule_id, value) }),
    ],
    [
      option([attribute.value("0")], "Mon"),
      option([attribute.value("1")], "Tue"),
      option([attribute.value("2")], "Wed"),
      option([attribute.value("3")], "Thu"),
      option([attribute.value("4")], "Fri"),
      option([attribute.value("5")], "Sat"),
      option([attribute.value("6")], "Sun"),
    ],
  )
}

fn assignment_shift_select(rule_id: Int, selected_value: Int) {
  select(
    [
      attribute.class("form-select"),
      attribute.value(int.to_string(selected_value)),
      on_change(fn(value) { app_model.UpdateAssignmentShiftTime(rule_id, value) }),
    ],
    [
      option([attribute.value("0")], "AM"),
      option([attribute.value("1")], "PM"),
    ],
  )
}

fn assignment_group_select(
  rule_id: Int,
  groups: List(StaffGroup),
  selected_group_id: Int,
) {
  select(
    [
      attribute.class("form-select"),
      attribute.value(int.to_string(selected_group_id)),
      on_change(fn(value) { app_model.UpdateAssignmentGroup(rule_id, value) }),
    ],
    groups
      |> list.map(fn(group) {
        option([attribute.value(int.to_string(group.id))], group.name)
      }),
  )
}

fn assignment_member_select(
  rule_id: Int,
  groups: List(StaffGroup),
  group_id: Int,
  member_index: Int,
) {
  let members = app_model.members_for_group(groups, group_id)
  let safe_member_index = app_model.clamp_member_index(member_index, members)

  select(
    [
      attribute.class("form-select"),
      attribute.value(int.to_string(safe_member_index)),
      on_change(fn(value) { app_model.UpdateAssignmentMember(rule_id, value) }),
    ],
    members
      |> list.index_map(fn(member, index) {
        option(
          [attribute.value(int.to_string(index))],
          "#" <> int.to_string(index) <> " " <> member.name,
        )
      }),
  )
}

fn calendar_rows(model: app_model.Model) -> List(Element(app_model.Msg)) {
  case model.calendar_state {
    app_model.LoadingData -> [p([], [text("Loading calendar...")])]
    app_model.FailedData(message) -> [p([], [text(message)])]
    _ ->
      model.calendar_grid
      |> list.index_map(fn(week, index) {
        render_calendar_row(model, index, week)
      })
  }
}

fn render_calendar_row(
  model: Model,
  index: Int,
  week: #(String, List(#(Int, Bool))),
) {
  let #(week_key, days) = week
  let week_state = app_model.week_display_state(model, index, week_key)

  div([attribute.class("cal-week-row")], [
    div([attribute.class("cal-cell-control")], [
      input([
        attribute.type_("checkbox"),
        attribute.checked(app_model.week_state_is_skip(week_state)),
        attribute.disabled(app_model.week_state_is_fixed(week_state)),
        on_check(fn(value) { app_model.ToggleWeekSkip(week_key, value) }),
      ]),
      p([attribute.class(app_model.status_text_class(week_state))], [text(app_model.week_state_label(week_state))]),
    ]),
    ..{
      days
      |> list.index_map(fn(day, day_index) {
        render_day_cell(
          day,
          app_model.day_shift_at(model.calendar_state, index, day_index),
        )
      })
    }
  ])
}

fn render_day_cell(day: #(Int, Bool), daily_shift: app_model.DailyShift) {
  let #(day_number, in_current_month) = day
  let opacity = case in_current_month {
    True -> "1"
    False -> "0.3"
  }

  div(
    [
      attribute.class("cal-cell-day"),
      attribute.attribute("style", "opacity:" <> opacity <> ";"),
    ],
    [
      p([attribute.class("day-number")], [text(int.to_string(day_number))]),
      div([attribute.class("day-shifts")], day_shift_badges(daily_shift)),
    ],
  )
}

fn day_shift_badges(daily_shift: app_model.DailyShift) -> List(Element(app_model.Msg)) {
  list.append(
    badge_if_assigned("AM", "morning", daily_shift.morning),
    badge_if_assigned("PM", "afternoon", daily_shift.afternoon),
  )
}

fn badge_if_assigned(
  label: String,
  class_name: String,
  names: List(String),
) -> List(Element(app_model.Msg)) {
  case names {
    [] -> []
    _ -> [render_shift_badge(label, class_name, names)]
  }
}

fn render_shift_badge(label: String, class_name: String, names: List(String)) {
  div(
    [attribute.class("shift-badge " <> class_name)],
    [
      p([attribute.class("shift-badge-label")], [text(label)]),
      div(
        [attribute.class("shift-badge-body")],
        names
        |> list.map(fn(name) {
          p([attribute.class("shift-name-pill")], [text(name)])
        }),
      ),
    ],
  )
}



fn plan_option(selected_plan: app_model.SelectedPlan, plan: app_model.Plan) {
  option(
    [
      attribute.value(int.to_string(plan.id)),
      attribute.selected(is_selected_plan(selected_plan, plan.id)),
    ],
    plan.name,
  )
}

fn is_selected_plan(selected_plan: app_model.SelectedPlan, plan_id: Int) -> Bool {
  case selected_plan {
    app_model.SelectedPlan(selected_id) -> selected_id == plan_id
    app_model.NoPlan -> False
  }
}

fn view_button_classes(is_active: Bool) {
  attribute.classes([#("view-btn", True), #("active", is_active)])
}
