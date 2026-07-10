export interface SessionCompactRegistrar {
  on(event: "session_compact", handler: () => void): void;
}

export function registerSessionCompactRefresh(
  pi: SessionCompactRegistrar,
  refresh: () => void,
): void {
  pi.on("session_compact", refresh);
}
