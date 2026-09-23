import os
import json
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

# ---------------------------------------------------------------------------
# Page config
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="Healthcare Intelligence Hub",
    page_icon=":material/local_hospital:",
    layout="wide",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

# ---------------------------------------------------------------------------
# Agent definitions
# ---------------------------------------------------------------------------
INTELLIGENCE_AGENT = "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT"

AGENTS = {
    "Healthcare Intelligence (orchestrator)": INTELLIGENCE_AGENT,
    "Visits Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.VISITS_AGENT",
    "Diagnoses Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.DIAGNOSES_AGENT",
    "Medications Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.MEDICATIONS_AGENT",
    "Claims Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.CLAIMS_AGENT",
    "Observations Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.OBSERVATIONS_AGENT",
    "Procedures Agent": "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.PROCEDURES_AGENT",
}

TOOL_META = {
    "Visits_Analyst":       {"icon": ":material/calendar_today:", "color": "#3B82F6", "label": "Visits",       "bg": "rgba(59,130,246,0.15)"},
    "Diagnoses_Analyst":    {"icon": ":material/biotech:",        "color": "#22C55E", "label": "Diagnoses",    "bg": "rgba(34,197,94,0.15)"},
    "Medications_Analyst":  {"icon": ":material/medication:",     "color": "#A855F7", "label": "Medications",  "bg": "rgba(168,85,247,0.15)"},
    "Claims_Analyst":       {"icon": ":material/payments:",       "color": "#F97316", "label": "Claims",       "bg": "rgba(249,115,22,0.15)"},
    "Observations_Analyst": {"icon": ":material/monitor_heart:",  "color": "#14B8A6", "label": "Observations", "bg": "rgba(20,184,166,0.15)"},
    "Procedures_Analyst":   {"icon": ":material/surgical:",       "color": "#EF4444", "label": "Procedures",   "bg": "rgba(239,68,68,0.15)"},
    "data_to_chart":        {"icon": ":material/bar_chart:",      "color": "#6366F1", "label": "Charts",       "bg": "rgba(99,102,241,0.15)"},
}

SAMPLE_QUESTIONS = [
    "How many visits by encounter class?",
    "What are the top 10 diagnoses?",
    "Which patients have the highest total claims?",
    "What medications are prescribed for patients with hypertension?",
    "Show me the most common lab tests and their average values",
    "Compare total claim costs for inpatient vs emergency visits",
    "Give me a summary: total visits, total claims cost, top 5 diagnoses, and most common procedures",
]

# ---------------------------------------------------------------------------
# Custom CSS for rich dark-themed UI
# ---------------------------------------------------------------------------
st.markdown("""
<style>
    .main-header {
        background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 50%, #2DD4BF 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        font-size: 2.5rem;
        font-weight: 800;
        letter-spacing: -0.02em;
        margin-bottom: 0;
    }
    .sub-header {
        color: #94A3B8;
        font-size: 1.05rem;
        margin-top: -0.5rem;
        margin-bottom: 1.5rem;
    }
    .tool-node {
        border-radius: 12px;
        padding: 12px 16px;
        text-align: center;
        font-weight: 600;
        font-size: 0.85rem;
        transition: all 0.3s;
        min-height: 70px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 4px;
    }
    .tool-active {
        box-shadow: 0 0 20px rgba(79,70,229,0.4);
        transform: scale(1.03);
    }
    .tool-inactive {
        opacity: 0.35;
    }
    .lineage-arrow {
        color: #4F46E5;
        font-size: 1.5rem;
        text-align: center;
        line-height: 2;
    }
    .orchestrator-badge {
        background: linear-gradient(135deg, #4F46E5, #7C3AED);
        color: white;
        padding: 8px 20px;
        border-radius: 20px;
        font-weight: 700;
        font-size: 0.9rem;
        display: inline-block;
        text-align: center;
        box-shadow: 0 4px 15px rgba(79,70,229,0.3);
    }
    .sql-block {
        background: #1E293B;
        border: 1px solid #334155;
        border-radius: 8px;
        padding: 12px;
        font-family: monospace;
        font-size: 0.82rem;
        overflow-x: auto;
    }
</style>
""", unsafe_allow_html=True)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
st.markdown('<div class="main-header">Healthcare Intelligence Hub</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">Enterprise Clinical Data Hub &mdash; AI-powered analytics across visits, diagnoses, medications, claims, observations &amp; procedures</div>', unsafe_allow_html=True)


# ---------------------------------------------------------------------------
# Sidebar
# ---------------------------------------------------------------------------
with st.sidebar:
    st.markdown("### :material/smart_toy: Agent selector")
    agent_choice = st.selectbox(
        "Choose agent",
        list(AGENTS.keys()),
        index=0,
        label_visibility="collapsed",
    )

    st.space("medium")
    st.markdown("### :material/architecture: Agent architecture")

    st.markdown("""
    ```
    User question
      |
      v
    Intelligence Agent
      |--- Visits Analyst
      |--- Diagnoses Analyst
      |--- Medications Analyst
      |--- Claims Analyst
      |--- Observations Analyst
      |--- Procedures Analyst
      |--- data_to_chart
      |
      v
    Response + Charts
    ```
    """)

    st.space("medium")
    st.markdown("### :material/lightbulb: Quick questions")
    for q in SAMPLE_QUESTIONS:
        if st.button(q, key=f"sample_{q}", use_container_width=True):
            st.session_state["prefill_question"] = q


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def call_agent(agent_fqn: str, question: str) -> dict:
    """Call a Cortex Agent via DATA_AGENT_RUN and return parsed JSON."""
    payload = json.dumps({
        "messages": [
            {"role": "user", "content": [{"type": "text", "text": question}]}
        ]
    })
    sql = f"""
    SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
        '{agent_fqn}',
        $${payload}$$,
        TRUE
    ) AS RESPONSE
    """
    row = conn.query(sql)
    raw = row.iloc[0]["RESPONSE"]
    return json.loads(raw) if isinstance(raw, str) else raw


def extract_tool_calls(response: dict) -> list[str]:
    """Return list of tool names called from the agent response."""
    tools = []
    for msg in response.get("messages", []):
        if msg.get("role") == "assistant":
            for block in msg.get("content", []):
                if block.get("type") == "tool_use":
                    tools.append(block.get("name", ""))
                if block.get("type") == "tool_results":
                    name = block.get("name", "")
                    if name:
                        tools.append(name)
    # Also check top-level tool_results / tool_calls
    for item in response.get("tool_results", []):
        if isinstance(item, dict) and item.get("name"):
            tools.append(item["name"])
    return list(dict.fromkeys(tools))  # unique, preserving order


def extract_text(response: dict) -> str:
    """Extract the assistant's text response."""
    texts = []
    for msg in response.get("messages", []):
        if msg.get("role") == "assistant":
            for block in msg.get("content", []):
                if block.get("type") == "text":
                    texts.append(block.get("text", ""))
    return "\n\n".join(texts) if texts else str(response)


def extract_sql(response: dict) -> list[str]:
    """Extract any SQL statements from tool results."""
    sqls = []
    for msg in response.get("messages", []):
        for block in msg.get("content", []):
            if block.get("type") == "tool_results":
                for res in block.get("content", []):
                    if isinstance(res, dict) and res.get("type") == "sql":
                        sqls.append(res.get("statement", ""))
            if isinstance(block, dict):
                stmt = block.get("statement", "")
                if stmt:
                    sqls.append(stmt)
    return sqls


def extract_data(response: dict) -> list[pd.DataFrame]:
    """Extract data results as DataFrames."""
    frames = []
    for msg in response.get("messages", []):
        for block in msg.get("content", []):
            if block.get("type") == "tool_results":
                for res in block.get("content", []):
                    if isinstance(res, dict) and res.get("type") == "data":
                        data = res.get("data", [])
                        if data:
                            frames.append(pd.DataFrame(data))
    return frames


def render_lineage(tools_called: list[str]):
    """Render the agent routing lineage visualization."""

    st.markdown("#### :material/account_tree: Agent routing")

    # Orchestrator node
    st.markdown(
        '<div style="text-align:center; margin-bottom:8px;">'
        '<span class="orchestrator-badge">Healthcare Intelligence Agent</span>'
        '</div>',
        unsafe_allow_html=True,
    )
    st.markdown('<div class="lineage-arrow">&#8595;</div>', unsafe_allow_html=True)

    # Tool nodes as columns
    tool_keys = [k for k in TOOL_META if k != "data_to_chart"]
    cols = st.columns(len(tool_keys))

    for col, key in zip(cols, tool_keys):
        meta = TOOL_META[key]
        is_active = key in tools_called
        active_cls = "tool-active" if is_active else "tool-inactive"
        border_color = meta["color"] if is_active else "#475569"
        bg_color = meta["bg"] if is_active else "rgba(71,85,105,0.1)"
        glow = f"0 0 16px {meta['color']}66" if is_active else "none"
        with col:
            st.markdown(
                f'<div class="tool-node {active_cls}" style="'
                f'border: 2px solid {border_color}; '
                f'background: {bg_color}; '
                f'color: {meta["color"] if is_active else "#64748B"}; '
                f'box-shadow: {glow};">'
                f'{meta["label"]}'
                f'</div>',
                unsafe_allow_html=True,
            )

    if "data_to_chart" in tools_called:
        st.markdown('<div class="lineage-arrow">&#8595;</div>', unsafe_allow_html=True)
        chart_meta = TOOL_META["data_to_chart"]
        st.markdown(
            f'<div style="text-align:center;">'
            f'<span style="background:{chart_meta["bg"]}; color:{chart_meta["color"]}; '
            f'padding:6px 16px; border-radius:16px; font-weight:600; font-size:0.85rem; '
            f'border:2px solid {chart_meta["color"]};">'
            f'data_to_chart</span></div>',
            unsafe_allow_html=True,
        )

    if tools_called:
        st.caption(f"Tools invoked: {', '.join(tools_called)}")
    else:
        st.caption("No tool calls detected in this response")


def auto_chart(df: pd.DataFrame):
    """Generate appropriate Plotly chart based on the data shape."""
    if df.empty or len(df.columns) < 2:
        return

    cols = df.columns.tolist()

    # Find numeric and categorical columns
    num_cols = df.select_dtypes(include=["number"]).columns.tolist()
    cat_cols = [c for c in cols if c not in num_cols]

    if not num_cols or not cat_cols:
        return

    cat = cat_cols[0]
    val = num_cols[0]

    # Color palette matching agent theme
    palette = ["#4F46E5", "#3B82F6", "#22C55E", "#A855F7", "#F97316", "#14B8A6",
               "#EF4444", "#6366F1", "#EC4899", "#F59E0B"]

    row_count = len(df)

    if row_count <= 6:
        # Pie chart for small distributions
        fig = px.pie(
            df, names=cat, values=val,
            color_discrete_sequence=palette,
            hole=0.4,
        )
        fig.update_layout(
            paper_bgcolor="rgba(0,0,0,0)",
            plot_bgcolor="rgba(0,0,0,0)",
            font_color="#E2E8F0",
            legend=dict(font=dict(color="#CBD5E1")),
            margin=dict(t=30, b=30, l=30, r=30),
        )
        st.plotly_chart(fig, use_container_width=True)
    else:
        # Horizontal bar for rankings
        df_sorted = df.sort_values(val, ascending=True).tail(15)
        fig = px.bar(
            df_sorted, x=val, y=cat, orientation="h",
            color_discrete_sequence=["#4F46E5"],
        )
        fig.update_layout(
            paper_bgcolor="rgba(0,0,0,0)",
            plot_bgcolor="rgba(0,0,0,0)",
            font_color="#E2E8F0",
            xaxis=dict(gridcolor="#334155", title_font_color="#94A3B8"),
            yaxis=dict(gridcolor="#334155", title_font_color="#94A3B8"),
            margin=dict(t=30, b=30, l=10, r=10),
        )
        st.plotly_chart(fig, use_container_width=True)

    # If multiple numeric columns, show a grouped bar
    if len(num_cols) > 1:
        fig2 = px.bar(
            df, x=cat, y=num_cols[:3], barmode="group",
            color_discrete_sequence=palette,
        )
        fig2.update_layout(
            paper_bgcolor="rgba(0,0,0,0)",
            plot_bgcolor="rgba(0,0,0,0)",
            font_color="#E2E8F0",
            xaxis=dict(gridcolor="#334155"),
            yaxis=dict(gridcolor="#334155"),
            margin=dict(t=30, b=30),
        )
        st.plotly_chart(fig2, use_container_width=True)


# ---------------------------------------------------------------------------
# Session state
# ---------------------------------------------------------------------------
if "messages" not in st.session_state:
    st.session_state.messages = []
if "prefill_question" not in st.session_state:
    st.session_state.prefill_question = None

# ---------------------------------------------------------------------------
# Chat history
# ---------------------------------------------------------------------------
for entry in st.session_state.messages:
    role = entry["role"]
    with st.chat_message(role, avatar=":material/person:" if role == "user" else ":material/smart_toy:"):
        st.markdown(entry["content"])

        # Re-render visuals for assistant messages
        if role == "assistant":
            if entry.get("dataframes"):
                for df_data in entry["dataframes"]:
                    df = pd.DataFrame(df_data) if isinstance(df_data, list) else df_data
                    chart_col, table_col = st.columns([3, 2])
                    with chart_col:
                        auto_chart(df)
                    with table_col:
                        st.dataframe(df, use_container_width=True, hide_index=True)

            if entry.get("sql_statements"):
                with st.expander(":material/code: Generated SQL", expanded=False):
                    for sql_stmt in entry["sql_statements"]:
                        st.code(sql_stmt, language="sql")

            if entry.get("tools_called"):
                with st.expander(":material/account_tree: Agent routing", expanded=False):
                    render_lineage(entry["tools_called"])


# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------
prefill = st.session_state.pop("prefill_question", None)
if prefill:
    question = prefill
else:
    question = st.chat_input("Ask your healthcare data a question...")

if question:
    # Show user message
    st.session_state.messages.append({"role": "user", "content": question})
    with st.chat_message("user", avatar=":material/person:"):
        st.write(question)

    # Call agent
    agent_fqn = AGENTS[agent_choice]
    with st.chat_message("assistant", avatar=":material/smart_toy:"):
        with st.spinner("Thinking..."):
            try:
                response = call_agent(agent_fqn, question)
            except Exception as e:
                st.error(f"Agent call failed: {e}")
                st.stop()

        # Extract response parts
        text = extract_text(response)
        tools_called = extract_tool_calls(response)
        sql_statements = extract_sql(response)
        dataframes = extract_data(response)

        # Render text response
        st.markdown(text)

        # Render data + charts
        if dataframes:
            for df in dataframes:
                chart_col, table_col = st.columns([3, 2])
                with chart_col:
                    auto_chart(df)
                with table_col:
                    st.dataframe(df, use_container_width=True, hide_index=True)

        # SQL accordion
        if sql_statements:
            with st.expander(":material/code: Generated SQL", expanded=False):
                for sql_stmt in sql_statements:
                    st.code(sql_stmt, language="sql")

        # Agent routing lineage
        if agent_fqn == INTELLIGENCE_AGENT and tools_called:
            with st.expander(":material/account_tree: Agent routing", expanded=True):
                render_lineage(tools_called)
        elif tools_called:
            st.caption(f"Tool used: {', '.join(tools_called)}")

        # Save to session
        st.session_state.messages.append({
            "role": "assistant",
            "content": text,
            "tools_called": tools_called,
            "sql_statements": sql_statements,
            "dataframes": [df.to_dict("records") for df in dataframes] if dataframes else [],
        })

    st.rerun()
