[![GoogleColab][googlecolab-shield]][googlecolab-url]
<div id="top"></div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://summerofcode.withgoogle.com/">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/GSoC-icon.svg/1200px-GSoC-icon.svg.png" alt="Logo" width="80" height="80">
  </a>
  <a href="https://www.chromium.org/chromium-projects/">
    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Chromium_Material_Icon.svg/640px-Chromium_Material_Icon.svg.png" alt="Logo" width="80" height="80">


  <h3 align="center">Google Summer of Code · Chromium</strong></h3>

  <p align="center">
    Make Perfetto Perfect: Animation Smoothness Alerts
    <br />
    <a href="https://summerofcode.withgoogle.com/programs/2022/projects/7Q8N05AW"><strong>Explore the Project »</strong></a>
    <br />
    <br />
    <a href="https://ui.perfetto.dev/">Perfetto Tracing</a>
    ·
   <a href="https://perfetto.dev/">
   <img src="https://ui.perfetto.dev/v25.0-b647cd253/assets/logo-3d.png" alt="Logo" width="30" height="30">
    ·  
    <a href="https://perfetto.dev/docs/analysis/sql-tables">SQL Tables</a>
  </p>
</div>

# Perfetto - System profiling, app tracing and trace analysis

Perfetto is a production-grade open-source stack for performance
instrumentation and trace analysis. It offers services and libraries and for
recording system-level and app-level traces, native + java heap profiling, a
library for analyzing traces using SQL and a web-based UI to visualize and
explore multi-GB traces.

See https://perfetto.dev/docs or the /docs/ directory for documentation.
### Perfetto build instructions

The source of truth for the Perfetto codebase lives in AOSP: https://android.googlesource.com/platform/external/perfetto/

A read-only mirror is also available at https://github.com/google/perfetto


**1. Clone the repo**

   ```sh
   git clone https://github.com/Patricijia/GSoC-Perfetto-Metrics.git
   ```
**2. Pull dependent libraries and toolchains**

   ```sh
   tools/install-build-deps [--ui] [--linux-arm]
   ```
**3. Build the UI**

   ```js
   ui/build
   ```
**4. Test your changes on a local server**

   ```js
   ui/run-dev-server
   ```

<!-- ABOUT THE PROJECT -->
# About The Project - Make Perfetto Perfect!

On Perfetto, users can get brilliant insights into the performance of applications through trace visualizations and metrics. Recently, core web vitals shaped a different view of a smooth website by bringing [Interaction to Next Paint](https://web.dev/inp/) metric to the light. Therefore, there is a need to update the Perfetto with the latest revolutionary metrics to provide better and faster insights to the developers of their web applications. The goal of this project is to improve the Perfetto tracing tool and visualize the core web vital metrics and INP in a consistent manner.
<br />
<br />
![INP](https://uploads-ssl.webflow.com/60e7ccafe29b4a10a36c0407/628d68347acd2d55e97c5065_inp-interaction-example.jpg)

## Interaction to Next Paint Definition on Perfetto
To begin with, the Interaction to Next Paint (INP) is an experimental field metric that assesses responsiveness. It consists of 3 main ingredients: input delay, processing time and presentation delay. They all together describe the duration of an event from the point at which the user interacted with the page until the next frame is presented after all associated event handlers have executed. To provide the best insight into the responsiveness of Perfetto we will be looking at the longest interaction durations *per frame*.

The very first step in obtaining the INP metric on Perfetto is analysing the EventTiming timeline. The EvenTiming track can be accessed by including the "devtools.timeline" checkmark in Additional Categories (recording configurations) when tracing any web app. Each renderer process has its own Event Timing timeline that can be found below EventLatency displaying some key statistics such as name, category, start time, duration, interactionId, etc. The interactions are determined to be the events of the EventTiming that have positive interactionId.

To dive deeper into the EventTiming measurement and metrics construction we use [SQL Tables](https://perfetto.dev/docs/analysis/sql-tables). The information on EventTiming can be obtained from the tables "slice" and"args" using SELECT, WHERE clauses, and [Helper Functions](https://perfetto.dev/docs/analysis/trace-processor). The longest interaction per frame of each browser is derived by using the MAX() function on the duration value "dur" and grouping the output by the interaction id. https://github.com/Patricijia/GSoC-Perfetto-Metrics/blob/main/event_timings.sql.

<a href="https://perfetto.dev/">
<img src="https://user-images.githubusercontent.com/64141509/175050934-20135eab-431a-46dd-b924-374812943347.svg" alt="Logo">


<p align="right">(<a href="#top">back to top</a>)</p>


[googlecolab-shield]: https://colab.research.google.com/assets/colab-badge.svg
[googlecolab-url]: https://colab.research.google.com/drive/1F7oZWFBeIU9iuXhumO8BsI72_rSbBiLG?usp=sharing
