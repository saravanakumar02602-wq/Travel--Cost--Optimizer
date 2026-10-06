
library(shiny)

ui <- fluidPage(

  # ==========================================================
  # CUSTOM CSS
  # ==========================================================

  tags$head(

    tags$title("TravelOptima"),

    tags$style(HTML("

      /* =====================================================
         GLOBAL
      ===================================================== */

      body {
        margin: 0;
        font-family: 'Segoe UI', Arial, sans-serif;

        background:
          linear-gradient(
            135deg,
            #07111f 0%,
            #101b35 45%,
            #1b1140 100%
          );

        color: white;
        min-height: 100vh;
      }


      .container-fluid {
        padding: 0 35px 40px 35px;
        max-width: 1600px;
        margin: auto;
      }


      /* =====================================================
         HEADER
      ===================================================== */

      .top-header {
        margin: 20px 0 25px 0;
        padding: 25px 30px;

        border-radius: 22px;

        background:
          linear-gradient(
            135deg,
            rgba(56,189,248,0.18),
            rgba(167,139,250,0.18)
          );

        border:
          1px solid rgba(255,255,255,0.12);

        box-shadow:
          0 15px 40px rgba(0,0,0,0.25);

        backdrop-filter: blur(18px);
      }


      .brand {
        font-size: 30px;
        font-weight: 800;
        letter-spacing: 0.5px;
      }


      .brand span {
        color: #38bdf8;
      }


      .subtitle {
        margin-top: 5px;
        color: rgba(255,255,255,0.65);
        font-size: 14px;
      }


      /* =====================================================
         GLASS CARD
      ===================================================== */

      .glass-card {
        background:
          rgba(255,255,255,0.07);

        border:
          1px solid rgba(255,255,255,0.12);

        border-radius: 20px;

        padding: 22px;

        margin-bottom: 22px;

        box-shadow:
          0 15px 40px rgba(0,0,0,0.20);

        backdrop-filter: blur(18px);
      }


      .section-title {
        font-size: 18px;
        font-weight: 700;
        margin-bottom: 18px;
        color: white;
      }


      /* =====================================================
         FORM INPUTS
      ===================================================== */

      label {
        color:
          rgba(255,255,255,0.75) !important;

        font-weight: 600;
      }


      .form-control,
      .selectize-input {

        background:
          rgba(255,255,255,0.08) !important;

        border:
          1px solid rgba(255,255,255,0.14) !important;

        color: white !important;

        border-radius: 12px !important;
      }


      .form-control:focus,
      .selectize-input.focus {

        border-color:
          #38bdf8 !important;

        box-shadow:
          0 0 0 2px rgba(56,189,248,0.15) !important;
      }


      .selectize-dropdown {

        background:
          #111b32 !important;

        color: white !important;
      }


      .selectize-dropdown-content .option {

        color: white !important;
      }


      /* =====================================================
         OPTIMIZE BUTTON
      ===================================================== */

      .btn-optimize {

        width: 100%;

        margin-top: 25px;

        padding: 13px;

        border: none;

        border-radius: 13px;

        background:
          linear-gradient(
            135deg,
            #38bdf8,
            #8b5cf6
          );

        color: white;

        font-size: 16px;

        font-weight: 700;

        box-shadow:
          0 10px 25px rgba(56,189,248,0.25);

        transition: all 0.2s ease;
      }


      .btn-optimize:hover {

        transform: translateY(-2px);

        box-shadow:
          0 15px 30px rgba(139,92,246,0.30);

        color: white;
      }


      /* =====================================================
         HERO CARD
      ===================================================== */

      .hero-card {

        min-height: 230px;

        display: flex;

        flex-direction: column;

        justify-content: center;

        padding: 30px;

        border-radius: 24px;

        background:
          linear-gradient(
            135deg,
            rgba(56,189,248,0.18),
            rgba(139,92,246,0.20)
          );

        border:
          1px solid rgba(255,255,255,0.14);

        box-shadow:
          0 20px 50px rgba(0,0,0,0.25);

        backdrop-filter: blur(20px);
      }


      .hero-label {

        color:
          rgba(255,255,255,0.65);

        font-size: 14px;

        text-transform: uppercase;

        letter-spacing: 1px;
      }


      .hero-cost {

        font-size: 45px;

        font-weight: 800;

        margin: 5px 0;

        color: white;
      }


      .hero-route {

        font-size: 17px;

        color:
          rgba(255,255,255,0.75);
      }


      .metric-box {

        background:
          rgba(255,255,255,0.06);

        border-radius: 14px;

        padding: 15px;

        margin-top: 18px;
      }


      .metric-label {

        color:
          rgba(255,255,255,0.55);

        font-size: 12px;
      }


      .metric-value {

        color: white;

        font-size: 20px;

        font-weight: 700;
      }


      /* =====================================================
         TRANSPORT COMPARISON
      ===================================================== */

      .transport-card {

        min-height: 205px;

        padding: 22px;

        border-radius: 18px;

        background:
          rgba(255,255,255,0.065);

        border:
          1px solid rgba(255,255,255,0.11);

        box-shadow:
          0 12px 30px rgba(0,0,0,0.18);

        transition:
          transform 0.2s ease,
          border 0.2s ease,
          box-shadow 0.2s ease;

        margin-bottom: 15px;
      }


      .transport-card:hover {

        transform: translateY(-5px);

        border:
          1px solid rgba(56,189,248,0.55);

        box-shadow:
          0 18px 35px rgba(0,0,0,0.25);
      }


      .transport-icon {

        font-size: 32px;

        margin-bottom: 8px;
      }


      .transport-name {

        font-size: 16px;

        font-weight: 700;

        color: white;
      }


      .transport-price {

        font-size: 25px;

        font-weight: 800;

        margin-top: 8px;

        color: #38bdf8;
      }


      .transport-info {

        font-size: 12px;

        color:
          rgba(255,255,255,0.55);

        margin-top: 7px;

        line-height: 1.6;
      }


      .recommended-label {

        display: inline-block;

        margin-top: 12px;

        padding: 5px 10px;

        border-radius: 20px;

        background:
          rgba(34,197,94,0.15);

        color: #4ade80;

        font-size: 11px;

        font-weight: 700;
      }


      /* =====================================================
         MAP
      ===================================================== */

      #route_map {

        height: 420px !important;

        border-radius: 18px;

        overflow: hidden;
      }


      /* =====================================================
         CHART
      ===================================================== */

      .chart-box {

        min-height: 420px;
      }


      /* =====================================================
         RECOMMENDATION
      ===================================================== */

      .recommendation-box {

        padding: 20px;

        border-radius: 16px;

        background:
          linear-gradient(
            135deg,
            rgba(56,189,248,0.10),
            rgba(139,92,246,0.10)
          );

        border:
          1px solid rgba(56,189,248,0.15);

        color:
          rgba(255,255,255,0.78);

        font-size: 15px;

        line-height: 1.8;
      }


      /* =====================================================
         SCENARIOS
      ===================================================== */

      .scenario-card {

        padding: 20px;

        border-radius: 16px;

        background:
          rgba(255,255,255,0.055);

        border:
          1px solid rgba(255,255,255,0.10);

        text-align: center;

        min-height: 130px;

        margin-bottom: 15px;
      }


      .scenario-title {

        font-size: 13px;

        color:
          rgba(255,255,255,0.60);

        text-transform: uppercase;

        letter-spacing: 0.8px;
      }


      .scenario-value {

        margin-top: 12px;

        font-size: 24px;

        font-weight: 800;

        color: white;
      }

      .recommendation-metric {
        padding: 12px 14px;
        margin-bottom: 12px;
        border-radius: 12px;
        background: rgba(255,255,255,0.055);
        border: 1px solid rgba(255,255,255,0.10);
        min-height: 72px;
      }

      .recommendation-metric strong,
      .recommendation-metric span {
        display: block;
      }

      .recommendation-metric strong {
        color: rgba(255,255,255,0.58);
        font-size: 12px;
        text-transform: uppercase;
      }

      .recommendation-metric span {
        color: white;
        font-size: 17px;
        font-weight: 700;
      }

      table {
        color: white !important;
        background: rgba(7,17,31,0.72) !important;
      }

      table th {
        color: #7dd3fc !important;
      }

      .nav-tabs > li > a {
        color: rgba(255,255,255,0.7);
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color: white;
        background: rgba(255,255,255,0.08);
        border-color: rgba(255,255,255,0.12);
      }


      /* =====================================================
         FOOTER
      ===================================================== */

      .footer {

        text-align: center;

        padding: 20px;

        color:
          rgba(255,255,255,0.40);

        font-size: 12px;
      }


      /* =====================================================
         MOBILE
      ===================================================== */

      @media (max-width: 900px) {

        .container-fluid {
          padding: 0 15px 25px 15px;
        }

        .hero-cost {
          font-size: 35px;
        }

        .transport-card {
          margin-bottom: 15px;
        }
      }
      /* =====================================================
         PROFESSIONAL LIGHT THEME
      ===================================================== */

      body {
        background:
          radial-gradient(ellipse at top left, #e0f2f1 0%, transparent 36%),
          linear-gradient(145deg, #f5f8fc 0%, #edf3f8 55%, #f8fafc 100%);
        color: #15283d;
      }

      .top-header {
        display: flex;
        align-items: center;
        min-height: 170px;
        background:
          linear-gradient(120deg, rgba(16,42,67,0.32) 0%, rgba(22,78,99,0.14) 58%, rgba(15,118,110,0.08) 100%),
          url('brand-header-background.jpg') center 10% / cover;
        border: 1px solid rgba(15, 42, 67, 0.12);
        box-shadow: 0 16px 36px rgba(15, 42, 67, 0.16);
      }

      .brand span {
        color: #5eead4;
      }

      .brand {
        color: #fff;
        text-shadow: 0 2px 12px rgba(7,25,43,0.55);
      }

      .subtitle {
        color: rgba(255,255,255,0.78);
        text-shadow: 0 1px 8px rgba(7,25,43,0.65);
      }

      .glass-card {
        background: rgba(255,255,255,0.94);
        border: 1px solid #dce6ef;
        box-shadow: 0 10px 28px rgba(15,42,67,0.07);
        backdrop-filter: none;
      }

      .section-title,
      .transport-name {
        color: #16324f;
      }

      label {
        color: #40566d !important;
      }

      .form-control,
      .selectize-input,
      .selectize-input input {
        background: #fff !important;
        border: 1px solid #cbd8e5 !important;
        color: #15283d !important;
      }

      .selectize-dropdown,
      .selectize-dropdown .option,
      .selectize-dropdown-content .option {
        background: #fff !important;
        color: #15283d !important;
      }

      .selectize-dropdown .active {
        background: #e6f4f2 !important;
        color: #0f5e59 !important;
      }

      .form-control:focus,
      .selectize-input.focus {
        border-color: #0f766e !important;
        box-shadow: 0 0 0 3px rgba(15,118,110,0.14) !important;
      }

      .btn-optimize {
        background: linear-gradient(120deg, #0f766e, #0e7490);
        box-shadow: 0 8px 20px rgba(15,118,110,0.20);
      }

      .btn-optimize:hover {
        background: linear-gradient(120deg, #115e59, #155e75);
        box-shadow: 0 12px 24px rgba(15,118,110,0.24);
      }

      .hero-card {
        background:
          linear-gradient(130deg, rgba(16,42,67,0.84), rgba(22,78,99,0.72) 62%, rgba(15,118,110,0.68)),
          url('trip-cost-background.jpg') center 58% / cover;
        border: 1px solid rgba(255,255,255,0.24);
        box-shadow: 0 16px 36px rgba(15,42,67,0.18);
        backdrop-filter: none;
      }

      .metric-box {
        background: rgba(255,255,255,0.11);
        border: 1px solid rgba(255,255,255,0.12);
      }

      .transport-card {
        background: #fff;
        border: 1px solid #dce6ef;
        box-shadow: 0 8px 20px rgba(15,42,67,0.06);
      }

      .transport-card:hover {
        border: 1px solid rgba(15,118,110,0.45);
        box-shadow: 0 12px 24px rgba(15,42,67,0.10);
      }

      .transport-price {
        color: #0f766e;
      }

      .transport-info {
        color: #5b6f82;
      }

      .recommendation-box {
        background: linear-gradient(120deg, #f0fdfa, #f1f7fb);
        border: 1px solid #cce9e5;
        color: #29445a;
      }

      .recommendation-metric {
        background: #fff;
        border: 1px solid #dce6ef;
      }

      .recommendation-metric strong {
        color: #63788b;
      }

      .recommendation-metric span {
        color: #16324f;
      }

      .scenario-card {
        background: #fff;
        border: 1px solid #dce6ef;
        box-shadow: 0 6px 16px rgba(15,42,67,0.05);
      }

      .scenario-title,
      .footer {
        color: #64788b;
      }

      .scenario-value {
        color: #16324f;
      }

      table {
        color: #243b53 !important;
        background: #fff !important;
      }

      table th {
        color: #0f5e59 !important;
        background: #f0f7f7 !important;
      }

      table td {
        color: #334e68 !important;
      }

      .table-responsive {
        width: 100%;
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
      }

      .table-responsive table {
        min-width: 760px;
      }

      .nav-tabs {
        border-bottom: 1px solid #cfdae5;
      }

      .nav-tabs > li > a {
        color: #52677c;
      }

      .nav-tabs > li > a:hover {
        background: #eaf2f6;
        border-color: #d6e2eb;
        color: #16324f;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color: #0f5e59;
        background: #fff;
        border-color: #cfdae5 #cfdae5 #fff;
      }

      .dashboard-hint,
      .estimate-notice {
        color: #52677c;
        font-size: 13px;
        line-height: 1.6;
      }

      .estimate-notice {
        padding: 12px 15px;
        margin-top: 14px;
        border-radius: 12px;
        background: #fff8e6;
        border: 1px solid #f3d89a;
        color: #6b4f16;
      }

      .status-bad {
        color: #9f2d2d;
      }

      .status-good {
        color: #0f6b4f;
      }

      .top-header-content {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 16px;
      }

      .welcome-banner {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 24px;
        min-height: 260px;
        margin: 0 0 24px;
        padding: 30px 36px;
        overflow: hidden;
        border-radius: 24px;
        background: linear-gradient(115deg, #102a43 0%, #164e63 55%, #0f766e 100%);
        box-shadow: 0 18px 38px rgba(15,42,67,0.17);
      }

      .welcome-copy {
        min-width: 0;
        max-width: 500px;
        position: relative;
        z-index: 1;
      }

      .welcome-kicker {
        color: #99f6e4;
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 1.5px;
        text-transform: uppercase;
      }

      .welcome-title {
        margin: 10px 0;
        color: #fff;
        font-size: clamp(28px, 3.2vw, 42px);
        font-weight: 800;
        line-height: 1.12;
      }

      .welcome-description {
        max-width: 450px;
        color: rgba(255,255,255,0.82);
        font-size: 15px;
        line-height: 1.6;
      }

      .welcome-cta {
        display: inline-flex;
        align-items: center;
        gap: 12px;
        margin-top: 12px;
        padding: 11px 18px;
        border-radius: 24px;
        background: linear-gradient(110deg, #14b8a6, #0e7490);
        color: #fff !important;
        font-weight: 700;
        text-decoration: none !important;
        box-shadow: 0 8px 20px rgba(6,95,90,0.25);
        transition: transform 0.18s ease, box-shadow 0.18s ease;
      }

      .welcome-cta:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 24px rgba(6,95,90,0.32);
      }

      .welcome-art {
        width: 48%;
        max-width: 520px;
        flex: 0 1 520px;
        filter: drop-shadow(0 12px 20px rgba(5,20,35,0.15));
      }

      .travel-illustration {
        display: block;
        width: 100%;
        height: 260px;
        border-radius: 22px;
        object-fit: cover;
        object-position: center 58%;
      }

      @media (max-width: 640px) {
        .top-header-content {
          gap: 5px;
        }

        .welcome-banner {
          flex-direction: column;
          align-items: flex-start;
          min-height: 0;
          padding: 24px 20px;
        }

        .welcome-art {
          align-self: center;
          width: 100%;
          max-width: 340px;
          margin: 4px 0 0;
        }
      }


    "))
  ),

  tabsetPanel(
    id = "dashboard_tabs",
    tabPanel(
      "Dashboard",


  # ==========================================================
  # HEADER
  # ==========================================================

  div(
    class = "top-header",

    div(
      class = "top-header-content",
      div(
        class = "brand",
        "✈️ Travel",
        span("Optima"),
        div(
          class = "subtitle",
          "Intelligent Travel Cost Optimization & Planning"
        )
      )
    )
  ),

  div(
    class = "welcome-banner",
    div(
      class = "welcome-copy",
      div(class = "welcome-kicker", "Plan smarter. Travel farther."),
      h1(class = "welcome-title", "Your next journey starts here"),
      p(
        class = "welcome-description",
        "Compare travel options, balance comfort with cost, and build a trip plan that fits your budget."
      ),
      tags$a(
        href = "#trip-planner",
        class = "welcome-cta",
        "Explore trip planner",
        tags$span("→", `aria-hidden` = "true")
      )
    ),
    div(
      class = "welcome-art",
      tags$img(
        src = "travel-hero.jpg",
        class = "travel-illustration",
        alt = "A boat on a turquoise alpine lake surrounded by mountains"
      )
    )
  ),


  # ==========================================================
  # INPUT + HERO
  # ==========================================================

  fluidRow(

    # --------------------------------------------------------
    # INPUT PANEL
    # --------------------------------------------------------

    column(

      width = 4,

      div(
        id = "trip-planner",
        class = "glass-card",

        div(
          class = "section-title",
          "🧭 Trip Planner"
        ),


        textInput(
          "origin",
          "Origin",
          value = "Chennai",
          placeholder = "City, Country (e.g., Chennai, India)"
        ),


        textInput(
          "destination",
          "Destination",
          value = "Goa",
          placeholder = "City, Country (e.g., Tokyo, Japan)"
        ),

        p(
          class = "dashboard-hint",
          "International cities include Dubai, Singapore, London, Paris, Tokyo, New York and more. Estimates are in INR; international non-transport costs use Indian dataset benchmarks."
        ),


        fluidRow(

          column(

            6,

            numericInput(
              "travelers",
              "Travelers",
              value = 2,
              min = 1,
              max = 50
            )
          ),

          column(

            6,

            numericInput(
              "days",
              "Days",
              value = 5,
              min = 1,
              max = 365
            )
          )
        ),


        numericInput(
          "budget",
          "Total Budget (₹)",
          value = 25000,
          min = 1,
          step = 500
        ),


        selectInput(
          "preference",

          "Travel Preference",

          choices = c(

            "Balanced" = "balanced",

            "Budget" = "budget",

            "Comfort" = "comfort",

            "Luxury" = "luxury"

          ),

          selected = "balanced"
        ),

        selectInput(
          "accommodation",
          "Accommodation",
          choices = c(
            "Automatic (optimizer chooses)" = "automatic",
            "Budget" = "budget",
            "Mid-range" = "mid",
            "Luxury" = "luxury"
          ),
          selected = "automatic"
        ),


        actionButton(

          "optimize",

          "⚡ OPTIMIZE MY TRIP",

          class = "btn-optimize"
        )
      )
    ),


    # --------------------------------------------------------
    # HERO PANEL
    # --------------------------------------------------------

    column(

      width = 8,

      div(

        class = "hero-card",

        div(
          class = "hero-label",
          "OPTIMIZED TRIP COST"
        ),


        div(

          class = "hero-cost",

          textOutput(
            "total_cost",
            inline = TRUE
          )
        ),


        div(

          class = "hero-route",

          textOutput(
            "hero_origin",
            inline = TRUE
          ),

          " → ",

          textOutput(
            "hero_destination",
            inline = TRUE
          )
        ),


        fluidRow(

          column(

            4,

            div(

              class = "metric-box",

              div(
                class = "metric-label",
                "COST / PERSON"
              ),

              div(

                class = "metric-value",

                textOutput(
                  "cost_per_person",
                  inline = TRUE
                )
              )
            )
          ),


          column(

            4,

            div(

              class = "metric-box",

              div(
                class = "metric-label",
                "REMAINING BUDGET"
              ),

              div(

                class = "metric-value",

                textOutput(
                  "remaining_budget",
                  inline = TRUE
                )
              )
            )
          ),


          column(

            4,

            div(

              class = "metric-box",

              div(
                class = "metric-label",
                "OPTIMIZATION SCORE"
              ),

              div(

                class = "metric-value",

                textOutput(
                  "optimization_score",
                  inline = TRUE
                )
              )
            )
          )
        )
      )
    )
  ),
  # ==========================================================
  # TRANSPORT COMPARISON
  # ==========================================================

  div(

    class = "glass-card",

    div(
      class = "section-title",
      "🚘 Compare Transportation"
    ),


    fluidRow(

      # ------------------------------------------------------
      # FLIGHT
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "transport-card",

          div(
            class = "transport-icon",
            "✈️"
          ),

          div(
            class = "transport-name",
            "Flight"
          ),

          div(

            class = "transport-price",

            textOutput(
              "flight_price",
              inline = TRUE
            )
          ),

          div(

            class = "transport-info",

            textOutput(
              "flight_info",
              inline = TRUE
            )
          ),

          uiOutput(
            "flight_status"
          )
        )
      ),


      # ------------------------------------------------------
      # TRAIN
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "transport-card",

          div(
            class = "transport-icon",
            "🚆"
          ),

          div(
            class = "transport-name",
            "Train"
          ),

          div(

            class = "transport-price",

            textOutput(
              "train_price",
              inline = TRUE
            )
          ),

          div(

            class = "transport-info",

            textOutput(
              "train_info",
              inline = TRUE
            )
          ),

          uiOutput(
            "train_status"
          )
        )
      ),


      # ------------------------------------------------------
      # BUS
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "transport-card",

          div(
            class = "transport-icon",
            "🚌"
          ),

          div(
            class = "transport-name",
            "Bus"
          ),

          div(

            class = "transport-price",

            textOutput(
              "bus_price",
              inline = TRUE
            )
          ),

          div(

            class = "transport-info",

            textOutput(
              "bus_info",
              inline = TRUE
            )
          ),

          uiOutput(
            "bus_status"
          )
        )
      ),


      # ------------------------------------------------------
      # CAR
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "transport-card",

          div(
            class = "transport-icon",
            "🚗"
          ),

          div(
            class = "transport-name",
            "Car"
          ),

          div(

            class = "transport-price",

            textOutput(
              "car_price",
              inline = TRUE
            )
          ),

          div(

            class = "transport-info",

            textOutput(
              "car_info",
              inline = TRUE
            )
          ),

          uiOutput(
            "car_status"
          )
        )
      )
    )
  ),
  div(
    class = "glass-card",
    plotOutput("transport_plot", height = "300px"),
    div(class = "table-responsive", tableOutput("transport_table"))
  ),


  # ==========================================================
  # MAP + COST CHART
  # ==========================================================

  fluidRow(

    # --------------------------------------------------------
    # MAP
    # --------------------------------------------------------

    column(

      width = 7,

      div(

        class = "glass-card",

        div(
          class = "section-title",
          "🗺️ Your Journey"
        ),

        leaflet::leafletOutput(
          "route_map",
          height = "420px"
        )
      )
    ),


    # --------------------------------------------------------
    # COST CHART
    # --------------------------------------------------------

    column(

      width = 5,

      div(

        class = "glass-card chart-box",

        div(
          class = "section-title",
          "💰 Cost Breakdown"
        ),

        plotOutput(
          "cost_plot",
          height = "470px"
        )
      )
    )
  ),


  # ==========================================================
  # SMART RECOMMENDATION
  # ==========================================================

  div(

    class = "glass-card",

    div(
      class = "section-title",
      "🤖 Smart Recommendation"
    ),


    div(
      class = "recommendation-box",
      uiOutput("recommendation_panel")
    )
  ),

  div(
    class = "glass-card",
    div(class = "section-title", "🔎 What-if Analysis"),
    p("Adjust trip assumptions and recalculate without changing your current plan."),
    fluidRow(
      column(2, numericInput("whatif_travelers", "Travelers", value = 2, min = 1, max = 50)),
      column(2, numericInput("whatif_days", "Days", value = 5, min = 1, max = 365)),
      column(3, numericInput("whatif_budget", "Budget (₹)", value = 25000, min = 1, step = 500)),
      column(
        2,
        selectInput(
          "whatif_preference",
          "Preference",
          choices = c("Budget" = "budget", "Balanced" = "balanced", "Comfort" = "comfort", "Luxury" = "luxury"),
          selected = "balanced"
        )
      ),
      column(
        3,
        selectInput(
          "whatif_accommodation",
          "Accommodation",
          choices = c("Automatic" = "automatic", "Budget" = "budget", "Mid-range" = "mid", "Luxury" = "luxury"),
          selected = "automatic"
        )
      )
    ),
    actionButton("run_whatif", "Recalculate What-if Plan", class = "btn-optimize"),
    uiOutput("whatif_summary")
  ),

  div(
    class = "glass-card",
    div(class = "section-title", "📄 Download Travel Report"),
    p("Export the current optimized trip, cost breakdown, and budget summary."),
    downloadButton("download_report", "Download Travel Report")
  ),
  div(
    class = "glass-card",
    div(class = "section-title", "📚 My Trips"),
    actionButton("save_trip", "Save Current Trip", class = "btn-optimize"),
    actionButton("refresh_history", "Refresh trip history"),
    div(class = "table-responsive", tableOutput("trip_history"))
  ),

  # ==========================================================
  # SCENARIO ANALYSIS
  # ==========================================================

  div(

    class = "glass-card",

    div(
      class = "section-title",
      "🎯 Trip Scenario Comparison"
    ),


    fluidRow(

      # ------------------------------------------------------
      # BUDGET
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "scenario-card",

          div(
            class = "scenario-title",
            "💚 Budget"
          ),

          div(

            class = "scenario-value",

            textOutput(
              "scenario_budget",
              inline = TRUE
            )
          ),

          textOutput("scenario_budget_status")
        )
      ),


      # ------------------------------------------------------
      # BALANCED
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "scenario-card",

          div(
            class = "scenario-title",
            "💙 Balanced"
          ),

          div(

            class = "scenario-value",

            textOutput(
              "scenario_balanced",
              inline = TRUE
            )
          ),

          textOutput("scenario_balanced_status")
        )
      ),


      # ------------------------------------------------------
      # COMFORT
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "scenario-card",

          div(
            class = "scenario-title",
            "💜 Comfort"
          ),

          div(

            class = "scenario-value",

            textOutput(
              "scenario_comfort",
              inline = TRUE
            )
          ),

          textOutput("scenario_comfort_status")
        )
      ),


      # ------------------------------------------------------
      # LUXURY
      # ------------------------------------------------------

      column(

        width = 3,

        div(

          class = "scenario-card",

          div(
            class = "scenario-title",
            "✨ Luxury"
          ),

          div(

            class = "scenario-value",

            textOutput(
              "scenario_luxury",
              inline = TRUE
            )
          ),

          textOutput("scenario_luxury_status")
        )
      )
    ),
    div(class = "table-responsive", tableOutput("scenario_table"))
  ),

    ),

  tabPanel(
    "Analytics",
    div(
      class = "glass-card",
      div(class = "section-title", "📊 Travel Data Analytics"),
      tags$details(
        tags$summary("How estimates and source data are used"),
        tags$p(
          "Flight prices use the flight dataset when a matching route exists. ",
          "Hotel, food, activities, and local transport use destination tourism ranges; ",
          "city-matched hotel averages and restaurant item-price medians provide fallback estimates where tourism coverage is missing. ",
          "Train and bus fares are distance-based estimates, not quoted route fares. ",
          "Car fuel uses the latest available fuel-price observations for route cities, ",
          "with a 15 km/L mileage assumption and tolls estimated at ₹0.75/km. ",
          "Haversine distance is a straight-line route proxy, not road distance. ",
          "These are planning estimates, not live quotes."
        )
      ),
      div(
        class = "scenario-card",
        div(class = "scenario-title", "Average flight price"),
        div(class = "scenario-value", textOutput("analytics_average_flight", inline = TRUE))
      ),
      fluidRow(
        column(6, h4("Flight price distribution"), plotOutput("analytics_flight_distribution", height = "300px")),
        column(6, h4("Average flight price by airline"), plotOutput("analytics_airline_prices", height = "300px"))
      ),
      fluidRow(
        column(6, h4("Average hotel price by city"), plotOutput("analytics_hotel_prices", height = "300px")),
        column(6, h4("Food price distribution"), plotOutput("analytics_food_prices", height = "300px"))
      ),
      h4("Petrol price trend"),
      plotOutput("analytics_fuel_trend", height = "300px")
    )
  )
  ),


  # ==========================================================
  # FOOTER
  # ==========================================================

  div(

    class = "footer",

    "TravelOptima • R + Python • Intelligent Travel Cost Optimization"
  )
)
