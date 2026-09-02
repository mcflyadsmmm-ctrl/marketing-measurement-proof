{{ config(materialized='table') }}

select
    kpi_name,
    kpi_label,
    definition,
    grain,
    audience,
    distrust_note
from (
    select
        'cash_mer' as kpi_name,
        'Cash MER' as kpi_label,
        'net_cash / spend. Net cash is order gross minus returns. Spend is media cost. Compare company_mer to break_even_mer.' as definition,
        'date x paid channel (last-click cash numerator) and company-day' as grain,
        'Finance / CMO' as audience,
        'Not platform ROAS. Last-click cash by channel is still attribution, not incrementality.' as distrust_note
    union all
    select
        'break_even_mer',
        'Break-even MER',
        '1 / contribution_margin from seeds/assumptions.csv. SAMPLE 0.40 contribution → 2.50 break-even MER.',
        'constant (SAMPLE assumption, not a W-2 margin)',
        'Finance',
        'Do not treat this SAMPLE 2.50 as a client or employer figure.'
    union all
    select
        'contribution_margin',
        'Contribution margin',
        'Share of net cash remaining after variable product cost. Used only to set break-even MER.',
        'constant (SAMPLE assumption)',
        'Finance',
        'SAMPLE. Not Black Clover, Nutricost, or any W-2 brand.'
    union all
    select
        'net_cash',
        'Net cash',
        'Order gross minus returns. The cash numerator for MER.',
        'order, rolled to day and to last-click channel',
        'Finance',
        'Excludes tax/shipping nuance in this SAMPLE. Still cash, not pixels.'
    union all
    select
        'spend',
        'Media spend',
        'Paid media cost by day and channel (Google, Meta, TikTok, Microsoft).',
        'date x paid channel',
        'Media / Finance',
        'Email has no media spend in this SAMPLE.'
    union all
    select
        'company_mer',
        'Company cash MER',
        'Sum of net_cash / sum of paid spend for the day. The finance KPI vs break-even.',
        'day (repeated on each paid-channel row in fct_daily_mer)',
        'Finance / CMO',
        'Use this, not stacked channel ROAS, when asking if the mix paid for itself.'
    union all
    select
        'claimed_revenue',
        'Platform-claimed revenue',
        'Paid: platform_reported_conversions x SAMPLE AOV. Email: Klaviyo-shaped last-click attributed_revenue.',
        'channel over the SAMPLE window',
        'Measurement',
        'Channels double-count the same orders. Sum of claimed_revenue exceeds company net_cash. That is the lesson.'
    union all
    select
        'platform_reported_conversions',
        'Platform-reported conversions',
        'Pixel / platform conversion count. Not unique orders. View-through and overlapping windows inflate it.',
        'date x paid channel',
        'Measurement',
        'Do not multiply by AOV and call it cash.'
    union all
    select
        'email_attributed_revenue',
        'Email last-click attributed revenue',
        'Klaviyo-shaped last-click revenue on sends. Inflated vs email last-click net_cash and vs company cash.',
        'day, rolled to Email in fct_channel_claimed_vs_cash',
        'CRM / Measurement',
        'Distrust. Last-click email is not incrementality and is not cash MER.'
    union all
    select
        'session_cvr',
        'Session conversion rate',
        'converting_sessions / sessions. Site-level, not a paid channel KPI.',
        'day',
        'Analytics',
        'GA-like. Do not stitch this to platform conversions and call it incrementality.'
) as kpis
