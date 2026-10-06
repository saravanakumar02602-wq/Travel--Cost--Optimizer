
library(shiny)
library(leaflet)
library(ggplot2)

run_optimizer <- function(origin,
                          destination,
                          days,
                          travelers,
                          budget,
                          preference,
                          accommodation_level = "automatic") {

  python_path <- file.path(project_root, ".venv", "Scripts", "python.exe")
  engine_path <- file.path(project_root, "python", "dashboard_engine.py")

  result <- system2(
    command = python_path,
    args = c(
      shQuote(engine_path),
      "--origin", shQuote(origin),
      "--destination", shQuote(destination),
      "--days", as.character(days),
      "--travelers", as.character(travelers),
      "--budget", as.character(budget),
      "--preference", shQuote(preference),
      "--accommodation", shQuote(accommodation_level)
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  exit_status <- attr(result, "status")

  if (!is.null(exit_status) && exit_status != 0) {
    stop(
      paste(
        "Python optimizer failed:",
        paste(result, collapse = "\n")
      )
    )
  }

  if (length(result) == 0) {
    stop("Python optimizer returned no output.")
  }

  json_text <- paste(result, collapse = "")
  jsonlite::fromJSON(
    json_text,
    simplifyVector = FALSE
  )
}

run_history_command <- function(arguments) {
  python_path <- file.path(project_root, ".venv", "Scripts", "python.exe")
  history_path <- file.path(project_root, "python", "trip_history.py")
  quoted_arguments <- vapply(arguments, shQuote, character(1))
  output <- system2(
    python_path,
    args = c(shQuote(history_path), quoted_arguments),
    stdout = TRUE,
    stderr = TRUE
  )
  exit_status <- attr(output, "status")
  if (!is.null(exit_status) && exit_status != 0L) {
    stop(paste("Trip history operation failed:", paste(output, collapse = "\n")))
  }
  if (length(output) == 0L) {
    stop("Trip history returned no output.")
  }
  jsonlite::fromJSON(paste(output, collapse = ""), simplifyVector = FALSE)
}

server <- function(input, output, session) {

  # ============================================================
  # DEFAULT RESULT
  # ============================================================

  trip_result <- reactiveVal(NULL)
  whatif_result <- reactiveVal(NULL)
  trip_history <- reactiveVal(list())

  analysis_data <- reactive({
    base_dir <- file.path(project_root, "data", "processed")

    read_selected_csv <- function(filename, required_columns) {
      path <- file.path(base_dir, filename)
      if (!file.exists(path)) {
        stop(sprintf("Analytics dataset was not found: %s", path))
      }

      headers <- names(read.csv(
        path,
        nrows = 0,
        check.names = FALSE,
        stringsAsFactors = FALSE
      ))
      missing_columns <- setdiff(required_columns, headers)
      if (length(missing_columns) > 0L) {
        stop(sprintf(
          "%s is missing required column(s): %s",
          filename,
          paste(missing_columns, collapse = ", ")
        ))
      }

      column_classes <- rep("NULL", length(headers))
      names(column_classes) <- headers
      column_classes[required_columns] <- "character"

      read.csv(
        path,
        check.names = FALSE,
        stringsAsFactors = FALSE,
        colClasses = column_classes
      )
    }

    list(
      flights = read_selected_csv(
        "flights.csv",
        c("airline", "price")
      ),
      hotels = read_selected_csv(
        "hotels.csv",
        c("city", "price")
      ),
      food = read_selected_csv(
        "food.csv",
        "prices"
      ),
      fuel = read_selected_csv(
        "fuel_prices.csv",
        c("date", "petrol_price_inr_per_litre")
      )
    )
  })

  analytics_number <- function(values) {
    suppressWarnings(as.numeric(gsub(
      "[^0-9.-]",
      "",
      as.character(values)
    )))
  }

  analytics_theme <- theme_minimal(base_size = 12) +
    theme(
      plot.background = element_rect(fill = "transparent", color = NA),
      panel.background = element_rect(fill = "transparent", color = NA),
      panel.grid.major = element_line(color = "#e2e8f0"),
      panel.grid.minor = element_blank(),
      axis.text = element_text(color = "#52677c"),
      axis.title = element_text(color = "#40566d"),
      plot.title = element_text(color = "#16324f")
    )

  set_trip_error <- function(message) {
    trip_result(list(
      status = "error",
      message = message,
      origin = if (is.null(input$origin) || !nzchar(trimws(input$origin))) {
        "Not specified"
      } else {
        trimws(input$origin)
      },
      destination = if (is.null(input$destination) || !nzchar(trimws(input$destination))) {
        "Not specified"
      } else {
        trimws(input$destination)
      },
      days = if (is_valid_count(input$days)) input$days else NULL,
      travelers = if (is_valid_count(input$travelers)) input$travelers else NULL,
      budget = if (is_valid_budget(input$budget)) input$budget else NULL
    ))
    whatif_result(NULL)
  }

  is_valid_count <- function(value) {
    is.numeric(value) &&
      length(value) == 1L &&
      is.finite(value) &&
      value >= 1 &&
      value == floor(value)
  }

  is_valid_budget <- function(value) {
    is.numeric(value) &&
      length(value) == 1L &&
      is.finite(value) &&
      value > 0
  }


  # ============================================================
  # RUN PYTHON OPTIMIZER
  # ============================================================

  observeEvent(input$optimize, {

    if (is.null(input$origin) || !nzchar(trimws(input$origin))) {
      set_trip_error("Enter an origin city.")
      showNotification("Enter an origin city.", type = "error", duration = 6)
      return()
    }
    if (is.null(input$destination) || !nzchar(trimws(input$destination))) {
      set_trip_error("Enter a destination city.")
      showNotification("Enter a destination city.", type = "error", duration = 6)
      return()
    }

    if (!is_valid_count(input$days)) {
      set_trip_error("Days must be a whole number of at least 1.")
      showNotification("Days must be a whole number of at least 1.", type = "error", duration = 6)
      return()
    }
    if (!is_valid_count(input$travelers)) {
      set_trip_error("Travelers must be a whole number of at least 1.")
      showNotification("Travelers must be a whole number of at least 1.", type = "error", duration = 6)
      return()
    }
    if (!is_valid_budget(input$budget)) {
      set_trip_error("Budget must be greater than 0.")
      showNotification("Budget must be greater than 0.", type = "error", duration = 6)
      return()
    }

    showNotification(
      "Optimizing your trip...",
      type = "message",
      duration = 2
    )

    parsed <- tryCatch(
      run_optimizer(
        origin = input$origin,
        destination = input$destination,
        days = input$days,
        travelers = input$travelers,
        budget = input$budget,
        preference = input$preference,
        accommodation_level = input$accommodation
      ),
      error = function(error) {
        list(status = "error", message = conditionMessage(error))
      }
    )

    if (is.null(parsed)) {
      message <- "The optimizer returned no result."
      set_trip_error(message)
      showNotification(message, type = "error", duration = 8)
      return()
    }

    if (identical(parsed$status, "error")) {
      set_trip_error(parsed$message)
      showNotification(parsed$message, type = "error", duration = 8)
      return()
    }

    # ----------------------------------------------------------
    # SAVE RESULT
    # ----------------------------------------------------------

    trip_result(parsed)
    whatif_result(NULL)
    if (identical(parsed$status, "success")) {
      updateNumericInput(session, "whatif_travelers", value = parsed$travelers)
      updateNumericInput(session, "whatif_days", value = parsed$days)
      updateNumericInput(session, "whatif_budget", value = parsed$budget)
      updateSelectInput(session, "whatif_preference", selected = parsed$preference)
      updateSelectInput(
        session,
        "whatif_accommodation",
        selected = input$accommodation
      )
    }


    showNotification(
      "Trip optimization completed!",
      type = "message",
      duration = 3
    )

  }, ignoreInit = FALSE)

  refresh_trip_history <- function() {
    result <- run_history_command(c("list", "--limit", "100"))
    if (!identical(result$status, "success")) {
      stop(result$message)
    }
    trip_history(result$trips)
  }

  observeEvent(TRUE, {
    tryCatch(
      refresh_trip_history(),
      error = function(error) {
        showNotification(
          conditionMessage(error),
          type = "error",
          duration = 8
        )
      }
    )
  }, once = TRUE)

  observeEvent(input$refresh_history, {
    tryCatch(
      refresh_trip_history(),
      error = function(error) {
        showNotification(
          conditionMessage(error),
          type = "error",
          duration = 8
        )
      }
    )
  })

  observeEvent(input$save_trip, {
    result <- trip_result()
    if (is.null(result) || !identical(result$status, "success")) {
      showNotification(
        "Optimize a feasible trip before saving it to trip history.",
        type = "warning",
        duration = 6
      )
      return()
    }

    arguments <- c(
      "save",
      "--origin", result$origin,
      "--destination", result$destination,
      "--travelers", as.character(result$travelers),
      "--days", as.character(result$days),
      "--budget", as.character(result$budget),
      "--preference", result$preference,
      "--transport-mode", result$transport_mode,
      "--total", as.character(result$total),
      "--cost-per-person", as.character(result$cost_per_person),
      "--optimization-score", as.character(result$optimization_score)
    )
    tryCatch({
      saved <- run_history_command(arguments)
      if (!identical(saved$status, "success")) {
        stop(saved$message)
      }
      refresh_trip_history()
      showNotification("Trip saved to history.", type = "message", duration = 4)
    }, error = function(error) {
      showNotification(conditionMessage(error), type = "error", duration = 8)
    })
  })

  observeEvent(input$run_whatif, {
    whatif_result(NULL)

    if (is.null(input$origin) || !nzchar(trimws(input$origin)) ||
        is.null(input$destination) || !nzchar(trimws(input$destination))) {
      message <- "Enter both origin and destination cities."
      whatif_result(list(status = "error", message = message))
      showNotification(message, type = "error", duration = 8)
      return()
    }

    if (!is_valid_count(input$whatif_days) ||
        !is_valid_count(input$whatif_travelers) ||
        !is_valid_budget(input$whatif_budget)) {
      message <- "What-if days and travelers must be whole numbers of at least 1, and budget must be greater than 0."
      whatif_result(list(status = "error", message = message))
      showNotification(message, type = "error", duration = 8)
      return()
    }

    result <- tryCatch(
      run_optimizer(
        origin = input$origin,
        destination = input$destination,
        days = input$whatif_days,
        travelers = input$whatif_travelers,
        budget = input$whatif_budget,
        preference = input$whatif_preference,
        accommodation_level = input$whatif_accommodation
      ),
      error = function(error) {
        list(status = "error", message = conditionMessage(error))
      }
    )

    if (is.null(result)) {
      message <- "The optimizer returned no what-if result."
      whatif_result(list(status = "error", message = message))
      showNotification(message, type = "error", duration = 8)
      return()
    }
    if (identical(result$status, "error")) {
      whatif_result(result)
      showNotification(result$message, type = "error", duration = 8)
      return()
    }
    whatif_result(result)
  })


  # ============================================================
  # INITIAL OPTIMIZATION
  # ============================================================

  observeEvent(TRUE, {

    if (is.null(trip_result())) {

      initial_result <- tryCatch(
        run_optimizer(
          origin = "Chennai",
          destination = "Goa",
          days = 5,
          travelers = 2,
          budget = 25000,
          preference = "balanced",
          accommodation_level = "automatic"
        ),
        error = function(error) {
          showNotification(
            conditionMessage(error),
            type = "error",
            duration = 8
          )
          NULL
        }
      )

      if (!is.null(initial_result)) {
        trip_result(initial_result)
        if (identical(initial_result$status, "error")) {
          showNotification(initial_result$message, type = "error", duration = 8)
        }
      }
    }

  }, once = TRUE)


  # ============================================================
  # HELPER
  # ============================================================

  result_number <- function(value, field) {

    if (is.list(value)) {
      value <- unlist(
        value,
        recursive = TRUE,
        use.names = FALSE
      )
    }

    if (length(value) != 1L) {
      stop(
        sprintf(
          "Optimizer result field '%s' must contain one number.",
          field
        )
      )
    }

    number <- suppressWarnings(as.numeric(value))

    if (is.na(number) || !is.finite(number)) {
      stop(
        sprintf(
          "Optimizer result field '%s' is not a finite number.",
          field
        )
      )
    }

    number
  }

  normalize_result_numbers <- function(result) {
    if (is.null(result$transport) && !is.null(result$transport_cost)) {
      result$transport <- result$transport_cost
    }

    numeric_fields <- c(
      "days",
      "travelers",
      "budget",
      "transport",
      "distance_km",
      "travel_time_hours",
      "hotel",
      "food",
      "activities",
      "local_transport",
      "contingency",
      "total",
      "cost_per_person",
      "remaining_budget",
      "optimization_score",
      "minimum_required_budget"
    )

    for (field in numeric_fields) {

      value <- result[[field]]

      if (is.null(value)) {
        next
      }

      result[[field]] <- result_number(value, field)
    }

    result
  }

  get_result <- reactive({

    req(trip_result())

    normalize_result_numbers(trip_result())

  })

  has_feasible_plan <- function(result) {
    identical(result$status, "success")
  }

  get_transport_option <- function(result, mode) {
    options <- result$transport_options

    if (!is.list(options)) {
      return(NULL)
    }

    for (option in options) {
      if (identical(option$mode, mode)) {
        return(option)
      }
    }

    NULL
  }

  format_transport_price <- function(result, mode) {
    option <- get_transport_option(result, mode)

    if (is.null(option) || is.null(option$cost)) {
      return("Not available")
    }

    paste0(
      "₹",
      format(
        result_number(option$cost, paste0(mode, " cost")),
        big.mark = ",",
        nsmall = 2
      )
    )
  }

  format_transport_info <- function(result, mode) {
    option <- get_transport_option(result, mode)

    if (is.null(option)) {
      return("No estimate available for this route")
    }

    distance <- option$distance_km
    if (is.null(distance)) {
      distance <- result$distance_km
    }

    time <- option$time_hours
    if (is.null(time)) {
      time <- option$estimated_time_hours
    }

    details <- character()

    if (!is.null(distance) && is.finite(as.numeric(distance))) {
      details <- c(details, paste0(round(as.numeric(distance)), " km"))
    }

    if (!is.null(time) && is.finite(as.numeric(time))) {
      details <- c(details, paste0(round(as.numeric(time), 1), " hrs"))
    }

    if (identical(mode, "Flight") && !is.null(option$cost_source)) {
      details <- c(
        details,
        if (grepl("^distance-based", option$cost_source)) {
          "Distance-based fare estimate"
        } else {
          "Flight dataset fare"
        }
      )
    }

    if (identical(mode, "Car")) {
      fuel_price <- option$fuel_price_per_litre
      mileage <- option$mileage_km_per_litre
      if (!is.null(fuel_price) && !is.null(mileage)) {
        details <- c(
          details,
          paste0(
            "Fuel ₹",
            format(result_number(fuel_price, "fuel price"), nsmall = 2),
            "/L at ",
            result_number(mileage, "vehicle mileage"),
            " km/L"
          )
        )
      }
    }

    if (length(details) == 0L) {
      return(paste("Estimated total for", result$travelers, "travelers"))
    }

    paste(
      c(paste("Estimated for", result$travelers, "travelers"), details),
      collapse = " • "
    )
  }


  # ============================================================
  # HERO ORIGIN
  # ============================================================

  output$hero_origin <- renderText({

    result <- get_result()

    result$origin

  })


  # ============================================================
  # HERO DESTINATION
  # ============================================================

  output$hero_destination <- renderText({

    result <- get_result()

    result$destination

  })


  # ============================================================
  # TOTAL COST
  # ============================================================

  output$total_cost <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return("Optimization unavailable")
    }

    if (!has_feasible_plan(result)) {
      return("No plan within budget")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$total),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # COST PER PERSON
  # ============================================================

  output$cost_per_person <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return("—")
    }

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$cost_per_person),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # REMAINING BUDGET
  # ============================================================

  output$remaining_budget <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return("—")
    }

    if (!has_feasible_plan(result)) {
      minimum_budget <- result$minimum_required_budget
      if (is.null(minimum_budget)) {
        return("No feasible plan")
      }

      shortfall <- max(
        0,
        result_number(minimum_budget, "minimum_required_budget") -
          result_number(result$budget, "budget")
      )

      return(
        paste0(
          "Need at least ₹",
          format(
            result_number(minimum_budget, "minimum_required_budget"),
            big.mark = ",",
            nsmall = 0
          ),
          " (₹",
          format(shortfall, big.mark = ",", nsmall = 0),
          " short)"
        )
      )
    }

    paste0(
      "₹",
      format(
        as.numeric(result$remaining_budget),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # OPTIMIZATION SCORE
  # ============================================================

  output$optimization_score <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return("Unavailable")
    }

    if (!has_feasible_plan(result)) {
      return("—")
    }

    score <- as.numeric(
      result$optimization_score
    )

    paste0(
      round(score * 100, 1),
      "%"
    )

  })


  # ============================================================
  # TRANSPORT COST
  # ============================================================

  output$transport_cost <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return(result$message)
    }

    if (!has_feasible_plan(result)) {
      return("Compare options below")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$transport),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # TRANSPORT DETAILS
  # ============================================================

  output$transport_details <- renderText({

    result <- get_result()

    if (identical(result$status, "error")) {
      return(result$message)
    }

    if (!has_feasible_plan(result)) {
      return("No complete trip plan fits the selected budget")
    }

    mode <- result$transport_mode

    distance <- as.numeric(
      result$distance_km
    )

    time <- as.numeric(
      result$travel_time_hours
    )

    paste0(
      mode,
      " • ",
      round(distance, 0),
      " km • ",
      round(time, 1),
      " hrs"
    )

  })


  # ============================================================
  # HOTEL
  # ============================================================

  output$hotel_cost <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$hotel),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # FOOD
  # ============================================================

  output$food_cost <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$food),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # ACTIVITIES
  # ============================================================

  output$activity_cost <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$activities),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # LOCAL TRANSPORT
  # ============================================================

  output$local_transport_cost <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$local_transport),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # CONTINGENCY
  # ============================================================

  output$contingency_cost <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$contingency),
        big.mark = ",",
        nsmall = 2
      )
    )

  })


  # ============================================================
  # BUDGET
  # ============================================================

  output$budget_display <- renderText({

    result <- get_result()

    if (is.null(result$budget)) {
      return("—")
    }

    paste0(
      "₹",
      format(
        as.numeric(result$budget),
        big.mark = ",",
        nsmall = 0
      )
    )

  })


  # ============================================================
  # BUDGET STATUS
  # ============================================================

  output$budget_status <- renderText({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return(result$message)
    }

    result$budget_status

  })

  for (mode in c("Flight", "Train", "Bus", "Car")) {
    local({
      current_mode <- mode
      output_prefix <- tolower(current_mode)

      output[[paste0(output_prefix, "_price")]] <- renderText({
        result <- get_result()
        format_transport_price(result, current_mode)
      })

      output[[paste0(output_prefix, "_info")]] <- renderText({
        result <- get_result()
        format_transport_info(result, current_mode)
      })

      output[[paste0(output_prefix, "_status")]] <- renderUI({
        result <- get_result()
        option <- get_transport_option(result, current_mode)

        if (is.null(option)) {
          return(tags$span("Unavailable", class = "status-bad"))
        }

        within_budget <- option$within_budget
        if (is.null(within_budget)) {
          estimated_total <- option$estimated_total
          if (is.null(estimated_total)) {
            return(tags$span("Budget status unavailable", class = "status-bad"))
          }
          within_budget <- result_number(
            estimated_total,
            paste0(current_mode, " estimated trip total")
          ) <= result_number(result$budget, "budget")
        }

        if (isTRUE(within_budget)) {
          tags$span("Within budget", class = "status-good")
        } else {
          tags$span("Over budget", class = "status-bad")
        }
      })
    })
  }


  # ============================================================
  # RECOMMENDATION
  # ============================================================

  output$recommendation_panel <- renderUI({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      if (identical(result$status, "error")) {
        return(tags$div(class = "status-bad", result$message))
      }

      return(tags$div(
        class = "status-bad",
        tags$p(
          paste(
            result$message,
            "Try reducing travelers or trip days, or increasing the budget."
          )
        ),
        if (!is.null(result$cost_estimate_note) &&
            nzchar(result$cost_estimate_note)) {
          tags$div(class = "estimate-notice", result$cost_estimate_note)
        }
      ))
    }

    mode_icons <- c(Flight = "✈️", Train = "🚆", Bus = "🚌", Car = "🚗")
    icon <- unname(mode_icons[result$transport_mode])
    if (length(icon) == 0L || is.na(icon)) icon <- ""

    explain_scores <- c(
      cost = result_number(result$cost_score, "cost score"),
      travel_time = result_number(result$time_score, "time score"),
      comfort = result_number(result$comfort_score, "comfort score")
    )
    strongest <- names(explain_scores)[which.max(explain_scores)]
    reason <- sprintf(
      "The selected plan satisfies the ₹%s budget constraint and balances cost, travel time, and comfort. Its strongest component score is %s.",
      format(result_number(result$budget, "budget"), big.mark = ",", scientific = FALSE),
      gsub("_", " ", strongest)
    )

    metric <- function(label, value) {
      tags$div(
        class = "recommendation-metric",
        tags$strong(label),
        tags$span(value)
      )
    }

    tags$div(
      tags$h4("Recommended Transport"),
      tags$p(tags$span(icon), " ", result$transport_mode),
      fluidRow(
        column(4, metric("Estimated travel time", if (is.null(result$travel_time_hours)) "Not available" else paste(result$travel_time_hours, "hours"))),
        column(4, metric("Distance", paste(format(result_number(result$distance_km, "distance"), big.mark = ","), "km"))),
        column(4, metric("Total trip cost", paste0("₹", format(result_number(result$total, "total"), big.mark = ",", nsmall = 2)))),
        column(4, metric("Cost per person", paste0("₹", format(result_number(result$cost_per_person, "cost per person"), big.mark = ",", nsmall = 2)))),
        column(4, metric("Remaining budget", paste0("₹", format(result_number(result$remaining_budget, "remaining budget"), big.mark = ",", nsmall = 2)))),
        column(4, metric("Optimization score", format(result_number(result$optimization_score, "optimization score"), nsmall = 4)))
      ),
      tags$p(tags$strong("Reason: "), reason),
      if (!is.null(result$cost_estimate_note) &&
          nzchar(result$cost_estimate_note)) {
        tags$div(class = "estimate-notice", result$cost_estimate_note)
      }
    )

  })

  output$transport_plot <- renderPlot({
    result <- get_result()
    if (!is.list(result$transport_options) || length(result$transport_options) == 0L) {
      plot.new()
      text(0.5, 0.5, "Transport comparison is unavailable.")
      return(invisible(NULL))
    }

    options <- result$transport_options
    comparison <- data.frame(
      mode = vapply(options, `[[`, character(1), "mode"),
      cost = vapply(options, function(option) {
        result_number(option$cost, paste(option$mode, "cost"))
      }, numeric(1))
    )
    ggplot(comparison, aes(x = reorder(mode, cost), y = cost, fill = mode)) +
      geom_col(show.legend = FALSE, width = 0.68) +
      geom_text(
        aes(label = paste0("₹", format(round(cost), big.mark = ","))),
        hjust = -0.12,
        color = "white"
      ) +
      coord_flip() +
      expand_limits(y = max(comparison$cost) * 1.2) +
      labs(title = "Transport comparison", x = NULL, y = "Estimated transport cost (₹)") +
      scale_fill_manual(values = c(Flight = "#38bdf8", Train = "#22c55e", Bus = "#f59e0b", Car = "#a78bfa")) +
      analytics_theme
  })

  output$transport_table <- renderTable({
    result <- get_result()
    if (!is.list(result$transport_options) || length(result$transport_options) == 0L) {
      return(NULL)
    }

    options <- result$transport_options
    data.frame(
      Mode = vapply(options, `[[`, character(1), "mode"),
      Cost = vapply(options, function(option) {
        result_number(option$cost, paste(option$mode, "cost"))
      }, numeric(1)),
      `Time (hours)` = vapply(options, function(option) {
        if (is.null(option$time_hours)) NA_real_ else result_number(option$time_hours, "travel time")
      }, numeric(1)),
      `Distance (km)` = vapply(options, function(option) {
        if (is.null(option$distance_km)) NA_real_ else result_number(option$distance_km, "distance")
      }, numeric(1)),
      `Estimated trip total (₹)` = vapply(options, function(option) {
        if (is.null(option$estimated_total)) NA_real_ else result_number(option$estimated_total, "estimated trip total")
      }, numeric(1)),
      `Budget status` = vapply(options, function(option) {
        if (is.null(option$within_budget)) {
          "Unavailable"
        } else if (isTRUE(option$within_budget)) {
          "Within Budget"
        } else {
          "Over Budget"
        }
      }, character(1)),
      check.names = FALSE
    )
  }, digits = 2, na = "—", striped = TRUE, hover = TRUE, bordered = FALSE)

  output$scenario_table <- renderTable({
    result <- get_result()
    if (!is.list(result$scenarios) || length(result$scenarios) == 0L) {
      return(NULL)
    }

    scenarios <- result$scenarios
    data.frame(
      Scenario = vapply(scenarios, `[[`, character(1), "scenario"),
      `Transport mode` = vapply(scenarios, function(x) {
        if (is.null(x$transport_mode)) "Unavailable" else x$transport_mode
      }, character(1)),
      Hotel = vapply(scenarios, function(x) result_number(x$hotel_cost, "scenario hotel"), numeric(1)),
      Food = vapply(scenarios, function(x) result_number(x$food_cost, "scenario food"), numeric(1)),
      Activities = vapply(scenarios, function(x) result_number(x$activities, "scenario activities"), numeric(1)),
      `Local transport` = vapply(scenarios, function(x) result_number(x$local_transport, "scenario local transport"), numeric(1)),
      Transport = vapply(scenarios, function(x) result_number(x$transport_cost, "scenario transport"), numeric(1)),
      Contingency = vapply(scenarios, function(x) result_number(x$contingency, "scenario contingency"), numeric(1)),
      Total = vapply(scenarios, function(x) result_number(x$total_cost, "scenario total"), numeric(1)),
      `Budget status` = vapply(scenarios, `[[`, character(1), "budget_status"),
      check.names = FALSE
    )
  }, digits = 2, striped = TRUE, hover = TRUE, bordered = FALSE)

  output$trip_history <- renderTable({
    trips <- trip_history()
    if (!is.list(trips) || length(trips) == 0L) {
      return(data.frame(Message = "No saved trips yet."))
    }
    data.frame(
      Date = vapply(trips, function(trip) substr(trip$created_at, 1L, 10L), character(1)),
      Route = vapply(trips, function(trip) paste(trip$origin, "→", trip$destination), character(1)),
      Travelers = vapply(trips, function(trip) as.integer(trip$travelers), integer(1)),
      Days = vapply(trips, function(trip) as.integer(trip$days), integer(1)),
      Transport = vapply(trips, `[[`, character(1), "selected_transport"),
      Total = vapply(trips, function(trip) {
        paste0("₹", format(as.numeric(trip$total_cost), big.mark = ",", nsmall = 2))
      }, character(1)),
      Preference = vapply(trips, `[[`, character(1), "preference"),
      check.names = FALSE
    )
  }, striped = TRUE, hover = TRUE, bordered = FALSE)

  output$whatif_summary <- renderUI({
    result <- whatif_result()
    if (is.null(result)) {
      return(tags$p("Change the assumptions above and select Recalculate to compare a new plan."))
    }
    if (!has_feasible_plan(result)) {
      return(tags$div(class = "status-bad", result$message))
    }

    baseline <- trip_result()
    if (has_feasible_plan(baseline)) {
      change <- result_number(result$total, "what-if total") -
        result_number(baseline$total, "current total")
      change_text <- if (change > 0) {
        paste0("₹", format(change, big.mark = ",", nsmall = 2), " higher than the current estimate.")
      } else if (change < 0) {
        paste0("₹", format(abs(change), big.mark = ",", nsmall = 2), " lower than the current estimate.")
      } else {
        "The estimate is unchanged."
      }
    } else {
      change_text <- "No feasible current plan is available for a cost comparison."
    }
    accommodation_label <- if (input$whatif_accommodation == "automatic") {
      paste(tools::toTitleCase(result$accommodation_level), "(auto-selected)")
    } else {
      tools::toTitleCase(input$whatif_accommodation)
    }

    tags$div(
      class = "recommendation-box",
      tags$p(sprintf(
        "%s travelers • %s days • ₹%s budget • %s preference • %s accommodation",
        result$travelers,
        result$days,
        format(result$budget, big.mark = ",", scientific = FALSE),
        tools::toTitleCase(result$preference),
        accommodation_label
      )),
      tags$p(tags$strong("New estimated cost: "), paste0("₹", format(result_number(result$total, "what-if total"), big.mark = ",", nsmall = 2))),
      tags$p(tags$strong("Recommended transport: "), result$transport_mode),
      tags$p(change_text)
    )
  })

  output$download_report <- downloadHandler(
    filename = function() {
      paste0("travel-cost-report-", Sys.Date(), ".txt")
    },
    content = function(file) {
      result <- get_result()
      if (!has_feasible_plan(result)) {
        report <- c(
          "TRAVEL COST OPTIMIZER",
          if (identical(result$status, "error")) {
            "Trip optimization failed."
          } else {
            "No feasible plan is currently available."
          },
          paste("Route:", result$origin, "to", result$destination),
          paste("Message:", result$message)
        )
      } else {
        currency <- function(value, field) {
          paste0("₹", format(result_number(value, field), big.mark = ",", nsmall = 2))
        }
        report <- c(
          "TRAVEL COST OPTIMIZER",
          "",
          "Trip Details",
          "-------------------------",
          paste("Origin:", result$origin),
          paste("Destination:", result$destination),
          if (!is.null(result$origin_country) &&
              !identical(result$origin_country, "India")) {
            paste("Origin country:", result$origin_country)
          },
          if (!is.null(result$destination_country) &&
              !identical(result$destination_country, "India")) {
            paste("Destination country:", result$destination_country)
          },
          paste("Travelers:", result$travelers),
          paste("Days:", result$days),
          paste("Budget:", currency(result$budget, "budget")),
          if (!is.null(result$cost_estimate_note) &&
              nzchar(result$cost_estimate_note)) {
            c("", "ESTIMATE NOTE", result$cost_estimate_note)
          },
          "",
          "Recommended Plan",
          "-------------------------",
          paste("Transport:", result$transport_mode),
          paste("Distance:", format(result_number(result$distance_km, "distance"), big.mark = ","), "km"),
          paste("Travel Time:", if (is.null(result$travel_time_hours)) "Not available" else paste(result$travel_time_hours, "hours")),
          paste("Budget Status:", result$budget_status),
          "",
          "Cost Breakdown",
          "-------------------------",
          paste("Transport:", currency(result$transport, "transport")),
          paste("Hotel:", currency(result$hotel, "hotel")),
          paste("Food:", currency(result$food, "food")),
          paste("Activities:", currency(result$activities, "activities")),
          paste("Local Transport:", currency(result$local_transport, "local transport")),
          paste("Contingency:", currency(result$contingency, "contingency")),
          "",
          paste("Total:", currency(result$total, "total")),
          paste("Cost/Person:", currency(result$cost_per_person, "cost per person")),
          paste("Budget Remaining:", currency(result$remaining_budget, "remaining budget")),
          paste("Optimization Score:", format(result_number(result$optimization_score, "optimization score"), nsmall = 4))
        )
      }
      writeLines(enc2utf8(report), file, useBytes = TRUE)
    }
  )


  # ============================================================
  # BUDGET PROGRESS
  # ============================================================

  output$budget_progress <- renderUI({

    result <- get_result()

    if (!has_feasible_plan(result)) {
      return(
        tags$div(
          class = "status-bad",
          result$message
        )
      )
    }

    budget <- as.numeric(
      result$budget
    )

    total <- as.numeric(
      result$total
    )

    percentage <- (total / budget) * 100

    percentage <- max(
      0,
      min(100, percentage)
    )

    HTML(
      paste0(
        '<div style="height:100%;width:',
        percentage,
        '%;border-radius:20px;',
        'background:linear-gradient(90deg,#22c55e,#06b6d4);">',
        '</div>'
      )
    )

  })


  # ============================================================
  # COST BREAKDOWN CHART
  # ============================================================

  output$cost_plot <- renderPlot({

    result <- get_result()

    if (!identical(result$status, "success")) {
      plot_message <- result$message
      if (is.null(plot_message) || !nzchar(plot_message)) {
        plot_message <- "Cost breakdown is unavailable."
      }
      plot.new()
      text(
        0.5,
        0.5,
        plot_message
      )
      return(invisible(NULL))
    }

    cost_values <- tryCatch(
      vapply(
        c(
          "transport",
          "hotel",
          "food",
          "activities",
          "local_transport",
          "contingency"
        ),
        function(field) {
          result_number(result[[field]], field)
        },
        numeric(1)
      ),
      error = function(error) {
        plot.new()
        text(
          0.5,
          0.5,
          paste("Cost breakdown unavailable:", conditionMessage(error))
        )
        NULL
      }
    )

    if (is.null(cost_values)) {
      return(invisible(NULL))
    }

    costs <- data.frame(

      Category = c(
        "Transport\nIntercity journey",
        "Hotel\nStay during the trip",
        "Food\nMeals for all travelers",
        "Activities\nSightseeing & attractions",
        "Local transport\nGetting around locally",
        "Contingency\n10% reserve for extras"
      ),

      Cost = cost_values
    )


    ggplot(
      costs,
      aes(
        x = reorder(Category, Cost),
        y = Cost
      )
    ) +

      geom_col(
        fill = "#38bdf8",
        width = 0.65
      ) +

      geom_label(
        aes(label = paste0("₹", format(round(Cost), big.mark = ","))),
        hjust = -0.15,
        color = "#164e63",
        fill = "white",
        label.size = 0,
        label.padding = unit(0.12, "lines"),
        fontface = "bold",
        size = 3.2
      ) +

      scale_y_continuous(
        expand = expansion(mult = c(0, 0.4))
      ) +

      coord_flip() +

      labs(
        x = NULL,
        y = "Cost (₹)"
      ) +

      theme_minimal(base_size = 12) +

      theme(

        plot.background =
          element_rect(
            fill = "transparent",
            color = NA
          ),

        panel.background =
          element_rect(
            fill = "transparent",
            color = NA
          ),

        panel.grid.major =
          element_line(
            color = "#334155"
          ),

        panel.grid.minor =
          element_blank(),

        axis.text =
          element_text(
            color = "#334155",
            size = 9
          ),

        axis.text.y =
          element_text(
            color = "#164e63",
            size = 9,
            lineheight = 0.95,
            face = "bold"
          ),

        axis.text.x =
          element_blank(),

        axis.ticks.x =
          element_blank(),

        axis.title =
          element_text(
            color = "#334155"
          ),

        plot.margin =
          margin(8, 24, 8, 8)
      )

  })


  # ============================================================
  # MAP
  # ============================================================

  output$route_map <- renderLeaflet({

    result <- get_result()

    origin <- result$origin
    destination <- result$destination


    route <- result$route_coordinates
    if (is.null(route) || is.null(route$origin) || is.null(route$destination)) {
      return(
        leaflet() %>%
          addTiles() %>%
          addControl(
            html = htmltools::HTML(
              "<div style='background:#111b32;color:white;padding:8px 12px;border-radius:8px'>Route map unavailable for this input.</div>"
            ),
            position = "topright"
          )
      )
    }

    coordinates <- data.frame(
      city = c(origin, destination),
      lat = c(
        result_number(route$origin$latitude, "origin latitude"),
        result_number(route$destination$latitude, "destination latitude")
      ),
      lon = c(
        result_number(route$origin$longitude, "origin longitude"),
        result_number(route$destination$longitude, "destination longitude")
      )
    )


    start <- coordinates[
      tolower(coordinates$city) ==
        tolower(origin),
    ]

    end <- coordinates[
      tolower(coordinates$city) ==
        tolower(destination),
    ]


    if (
      nrow(start) == 0 ||
      nrow(end) == 0
    ) {

      return(
        leaflet() %>%
          addTiles() %>%
          addControl(
            html = htmltools::HTML(
              "<div style='background:#111b32;color:white;padding:8px 12px;border-radius:8px'>Route map unavailable for this input.</div>"
            ),
            position = "topright"
          )
      )

    }


    distance <- suppressWarnings(as.numeric(result$distance_km))
    distance_control <- if (length(distance) == 1L && is.finite(distance)) {
      paste0(
        "<div style='background:#111b32;color:white;padding:8px 12px;border-radius:8px'>",
        round(distance),
        " km",
        "</div>"
      )
    } else {
      NULL
    }

    leaflet() %>%
      addProviderTiles(
        providers$OpenStreetMap.Mapnik
      ) %>%
      addControl(
        html = htmltools::HTML(distance_control),
        position = "topright"
      ) %>%

      addCircleMarkers(
        lng = start$lon,
        lat = start$lat,

        radius = 9,

        color = "#38bdf8",
        fillColor = "#38bdf8",
        fillOpacity = 1,

        popup = paste0(
          "<b>Origin</b><br>",
          origin
        )
      ) %>%

      addCircleMarkers(
        lng = end$lon,
        lat = end$lat,

        radius = 9,

        color = "#a78bfa",
        fillColor = "#a78bfa",
        fillOpacity = 1,

        popup = paste0(
          "<b>Destination</b><br>",
          destination
        )
      ) %>%

      addPolylines(

        lng = c(
          start$lon,
          end$lon
        ),

        lat = c(
          start$lat,
          end$lat
        ),

        color = "#38bdf8",

        weight = 4,

        opacity = 0.8,

        dashArray = "8,8"
      ) %>%

      fitBounds(

        lng1 = start$lon,
        lat1 = start$lat,

        lng2 = end$lon,
        lat2 = end$lat
      )

  })


  # ============================================================
  # SCENARIO CALCULATOR
  # ============================================================

  scenario_values <- reactive({

    result <- get_result()

    scenarios <- result$scenarios
    if (!is.list(scenarios) || length(scenarios) == 0L) {
      return(NULL)
    }

    values <- lapply(scenarios, function(scenario) {
      list(
        name = scenario$scenario,
        total = result_number(scenario$total_cost, "scenario total"),
        status = scenario$budget_status
      )
    })
    names(values) <- vapply(values, `[[`, character(1), "name")
    values

  })


  # ============================================================
  # SCENARIO OUTPUTS
  # ============================================================

  output$scenario_budget <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    paste0("₹", format(values$Budget$total, big.mark = ",", nsmall = 2))
  })

  output$scenario_budget_status <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    values$Budget$status
  })

  output$scenario_balanced <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    paste0("₹", format(values$Balanced$total, big.mark = ",", nsmall = 2))
  })

  output$scenario_balanced_status <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    values$Balanced$status
  })

  output$scenario_comfort <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    paste0("₹", format(values$Comfort$total, big.mark = ",", nsmall = 2))
  })

  output$scenario_comfort_status <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    values$Comfort$status
  })

  output$scenario_luxury <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    paste0("₹", format(values$Luxury$total, big.mark = ",", nsmall = 2))
  })

  output$scenario_luxury_status <- renderText({
    values <- scenario_values()
    if (is.null(values)) return("Unavailable")
    values$Luxury$status
  })

  output$analytics_average_flight <- renderText({
    data <- analysis_data()
    prices <- analytics_number(data$flights$price)
    prices <- prices[is.finite(prices)]
    shiny::validate(shiny::need(
      length(prices) > 0L,
      "Flight price data is unavailable."
    ))
    paste0("₹", format(round(mean(prices), 2), big.mark = ",", nsmall = 2))
  })

  output$analytics_flight_distribution <- renderPlot({
    data <- analysis_data()
    data$flights$price <- analytics_number(data$flights$price)
    data$flights <- data$flights[is.finite(data$flights$price), , drop = FALSE]
    shiny::validate(shiny::need(
      nrow(data$flights) > 0L,
      "Flight price data is unavailable."
    ))
    ggplot(data$flights, aes(x = price)) +
      geom_histogram(bins = 30, fill = "#38bdf8", color = "#07111f") +
      labs(x = "Flight price (₹)", y = "Number of flights") +
      analytics_theme
  })

  output$analytics_airline_prices <- renderPlot({
    data <- analysis_data()
    data$flights$price <- analytics_number(data$flights$price)
    data$flights <- data$flights[
      is.finite(data$flights$price) & !is.na(data$flights$airline),
      ,
      drop = FALSE
    ]
    shiny::validate(shiny::need(
      nrow(data$flights) > 0L,
      "Airline price data is unavailable."
    ))
    averages <- aggregate(price ~ airline, data$flights, mean)
    averages <- head(averages[order(averages$price), ], 12)
    ggplot(averages, aes(x = reorder(airline, price), y = price)) +
      geom_col(fill = "#a78bfa", width = 0.7) +
      coord_flip() +
      labs(x = NULL, y = "Average flight price (₹)") +
      analytics_theme
  })

  output$analytics_hotel_prices <- renderPlot({
    data <- analysis_data()
    data$hotels$price <- analytics_number(data$hotels$price)
    data$hotels <- data$hotels[
      is.finite(data$hotels$price) & !is.na(data$hotels$city),
      ,
      drop = FALSE
    ]
    shiny::validate(shiny::need(
      nrow(data$hotels) > 0L,
      "Hotel price data is unavailable."
    ))
    averages <- aggregate(price ~ city, data$hotels, mean)
    ggplot(averages, aes(x = reorder(city, price), y = price)) +
      geom_col(fill = "#22c55e", width = 0.7) +
      coord_flip() +
      labs(x = NULL, y = "Average hotel price (₹)") +
      analytics_theme
  })

  output$analytics_food_prices <- renderPlot({
    data <- analysis_data()
    prices <- analytics_number(data$food$prices)
    prices <- prices[is.finite(prices)]
    shiny::validate(shiny::need(
      length(prices) > 0L,
      "Food price data is unavailable."
    ))
    ggplot(data.frame(price = prices), aes(x = price)) +
      geom_histogram(bins = 35, fill = "#f59e0b", color = "#07111f") +
      labs(x = "Food item price (₹)", y = "Number of items") +
      analytics_theme
  })

  output$analytics_fuel_trend <- renderPlot({
    data <- analysis_data()
    trend <- data.frame(
      date = as.Date(data$fuel$date),
      price = analytics_number(data$fuel$petrol_price_inr_per_litre)
    )
    trend <- trend[
      !is.na(trend$date) & is.finite(trend$price),
      ,
      drop = FALSE
    ]
    shiny::validate(shiny::need(
      nrow(trend) > 0L,
      "Fuel price history is unavailable."
    ))
    trend <- aggregate(price ~ date, trend, mean)
    ggplot(trend, aes(x = date, y = price)) +
      geom_line(color = "#38bdf8", linewidth = 0.8) +
      labs(x = NULL, y = "Average petrol price (₹/L)") +
      analytics_theme
  })

}