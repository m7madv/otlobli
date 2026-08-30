const revenueCatApiBaseUrl = "https://api.revenuecat.com/v1";

export class RevenueCatSubscriberDeletionError extends Error {
  constructor(
    public readonly code: string,
    public readonly status: number | null = null,
  ) {
    super(code);
    this.name = "RevenueCatSubscriberDeletionError";
  }
}

export type RevenueCatDeleteFetcher = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

export async function deleteAccountWithRevenueCatFirst(
  deleteRevenueCat: () => Promise<void>,
  deleteSupabase: () => Promise<void>,
): Promise<void> {
  await deleteRevenueCat();
  await deleteSupabase();
}

export async function deleteRevenueCatSubscriber(
  userId: string,
  secretApiKey: string,
  fetcher: RevenueCatDeleteFetcher = fetch,
): Promise<void> {
  if (!userId || !secretApiKey) {
    throw new RevenueCatSubscriberDeletionError("revenuecat_not_configured");
  }

  let response: Response;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15_000);
  try {
    response = await fetcher(
      `${revenueCatApiBaseUrl}/subscribers/${encodeURIComponent(userId)}`,
      {
        method: "DELETE",
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${secretApiKey}`,
        },
        redirect: "error",
        signal: controller.signal,
      },
    );
  } catch {
    throw new RevenueCatSubscriberDeletionError("revenuecat_unavailable");
  } finally {
    clearTimeout(timeout);
  }

  if (response.status === 200 || response.status === 404) return;
  throw new RevenueCatSubscriberDeletionError(
    "revenuecat_delete_failed",
    response.status,
  );
}
