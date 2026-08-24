begin;

revoke all on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer)
  from public, anon, authenticated;
revoke all on function public.mark_voicebrief_ai_started(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.complete_voicebrief_job(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.fail_voicebrief_job(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;

grant execute on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer)
  to service_role;
grant execute on function public.mark_voicebrief_ai_started(uuid, uuid)
  to service_role;
grant execute on function public.complete_voicebrief_job(uuid, uuid, jsonb)
  to service_role;
grant execute on function public.fail_voicebrief_job(uuid, uuid, text)
  to service_role;
grant execute on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) to service_role;

commit;
