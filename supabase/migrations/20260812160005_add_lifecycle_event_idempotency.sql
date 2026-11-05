-- Prevent duplicate processing of the same on-chain event.
-- Fail explicitly if existing data conflicts with the constraint.
-- Never delete payment lifecycle records automatically.

do $$
declare
  v_null_hash_count bigint;
  v_duplicate_groups bigint;
begin
  select count(*)
  into v_null_hash_count
  from public.lifecycle_events
  where tx_hash is null;

  if v_null_hash_count > 0 then
    raise exception
      'Cannot add lifecycle event uniqueness constraint: % rows have NULL tx_hash. Review and repair these rows first.',
      v_null_hash_count;
  end if;

  select count(*)
  into v_duplicate_groups
  from (
    select tx_hash, operation
    from public.lifecycle_events
    group by tx_hash, operation
    having count(*) > 1
  ) duplicates;

  if v_duplicate_groups > 0 then
    raise exception
      'Cannot add lifecycle event uniqueness constraint: % duplicate (tx_hash, operation) groups found. Review existing records before retrying.',
      v_duplicate_groups;
  end if;
end;
$$;

alter table public.lifecycle_events
  add constraint lifecycle_events_tx_hash_operation_key
  unique (tx_hash, operation);
