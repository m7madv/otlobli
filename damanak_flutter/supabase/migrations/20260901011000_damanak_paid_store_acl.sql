-- Keep the Build 25 onboarding entry point available only to a signed-in
-- client. Supabase's default function privileges grant service_role an
-- explicit EXECUTE entry, so remove it after the main onboarding migration.

revoke execute on function public.create_store_with_subscription(
  text, text, text, text, text
) from service_role;

revoke execute on function public.register_trial_device(uuid, text)
  from service_role;
revoke execute on function public.store_requires_initial_payment(uuid)
  from service_role;
revoke execute on function public.can_access_warranty_records(uuid)
  from service_role;

revoke execute on function private.ensure_default_store_branch(uuid)
  from service_role;
revoke execute on function public.create_default_store_branch()
  from service_role;
revoke execute on function
  public.ensure_default_store_branch_after_subscription()
  from service_role;
revoke execute on function public.reject_initial_payment_store_write()
  from service_role;
